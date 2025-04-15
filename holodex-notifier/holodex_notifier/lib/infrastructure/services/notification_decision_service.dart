// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\infrastructure\services\notification_decision_service.dart

// {{ Add necessary imports }}
import 'dart:async';
import 'package:collection/collection.dart'; // For listEquals deep equality
import 'package:drift/drift.dart'; // For Value()
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/channel_min.dart';
import 'package:holodex_notifier/domain/models/channel_min_with_org.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

// {{ --- Move _ProcessingState helper class here --- }}
class _ProcessingState {
  // Mutable state reflecting decisions made during processing
  int? scheduledLiveNotificationId;
  int? scheduledReminderNotificationId;
  DateTime? scheduledReminderTime;
  bool isPendingNewMedia = false;
  DateTime? lastLiveNotificationSentTime;

  // Immutable state transitions detected at the start
  final bool isNewVideo;
  final bool isCertain;
  final bool wasCertain;
  final bool statusChanged;
  final bool scheduleChanged;
  final bool becameCertain; // Derived: !wasCertain && isCertain
  final bool mentionsChanged;
  final bool wasPendingNewMedia;
  final bool reminderTimeChanged; // Tracks if the *potential* reminder time changed due to start_scheduled change

  _ProcessingState({required CachedVideo? currentCacheData, required VideoFull fetchedVideoData})
    : // Initialize immutable finals here
      isNewVideo = currentCacheData == null,
      isCertain = (fetchedVideoData.certainty == 'certain' || fetchedVideoData.certainty == null),
      wasCertain = currentCacheData != null && (currentCacheData.certainty == 'certain' || currentCacheData.certainty == null),
      statusChanged = currentCacheData != null && currentCacheData.status != fetchedVideoData.status,
      scheduleChanged = currentCacheData != null && currentCacheData.startScheduled != fetchedVideoData.startScheduled?.toIso8601String(),
      mentionsChanged =
          currentCacheData != null &&
          !const ListEquality().equals(
            // Use deep equality for lists
            currentCacheData.mentionedChannelIds,
            fetchedVideoData.mentions?.map((m) => m.id).whereType<String>().toList() ?? [],
          ),
      wasPendingNewMedia = currentCacheData?.isPendingNewMediaNotification ?? false,
      becameCertain =
          !(currentCacheData != null && (currentCacheData.certainty == 'certain' || currentCacheData.certainty == null)) &&
          (fetchedVideoData.certainty == 'certain' || fetchedVideoData.certainty == null), // Calculate derived state last
      // Check if the stored reminder time exists and if the *schedule* time (which determines reminder time) differs
      reminderTimeChanged =
          currentCacheData?.scheduledReminderTime != null && currentCacheData!.startScheduled != fetchedVideoData.startScheduled?.toIso8601String() {
    // Initialize mutable state from cache
    scheduledLiveNotificationId = currentCacheData?.scheduledLiveNotificationId;
    scheduledReminderNotificationId = currentCacheData?.scheduledReminderNotificationId;
    scheduledReminderTime =
        currentCacheData?.scheduledReminderTime != null ? DateTime.fromMillisecondsSinceEpoch(currentCacheData!.scheduledReminderTime!) : null;
    isPendingNewMedia = currentCacheData?.isPendingNewMediaNotification ?? false;
    lastLiveNotificationSentTime =
        currentCacheData?.lastLiveNotificationSentTime != null
            ? DateTime.fromMillisecondsSinceEpoch(currentCacheData!.lastLiveNotificationSentTime!)
            : null;
  }
}
// {{ --- End _ProcessingState helper class --- }}

class NotificationDecisionService implements INotificationDecisionService {
  final ICacheService _cacheService;
  final ISettingsService _settingsService;
  final ILoggingService _logger;

  NotificationDecisionService(this._cacheService, this._settingsService, this._logger);

  @override
  Future<List<NotificationAction>> determineActionsForVideoUpdate({required VideoFull fetchedVideo, required CachedVideo? cachedVideo}) async {
    final String videoId = fetchedVideo.id;
    final List<NotificationAction> actions = [];
    final DateTime currentSystemTime = DateTime.now(); // Consistent time for checks
    _logger.debug("[DecisionService] ($videoId) Determining actions for video update...");

    try {
      // --- 1. Get Settings ---
      _logger.debug("[DecisionService] ($videoId) Getting channel settings...");
      // Assume channel settings are passed correctly or fetched if needed.
      // Here we fetch them individually for this video's channel.
      final List<ChannelSubscriptionSetting> allSettings = await _settingsService.getChannelSubscriptions();
      final channelSettings = allSettings.firstWhereOrNull((s) => s.channelId == fetchedVideo.channel.id);

      if (channelSettings == null) {
        _logger.warning("[DecisionService] ($videoId) No settings found for channel ${fetchedVideo.channel.id}. Skipping decision logic.");
        return []; // Cannot determine actions without settings
      }
      _logger.debug("[DecisionService] ($videoId) Getting global settings...");
      final bool delayNewMedia = await _settingsService.getDelayNewMedia();
      final Duration reminderLeadTime = await _settingsService.getReminderLeadTime();

      // --- 2. Check Base Conditions ---
      _logger.debug("[DecisionService] ($videoId) Checking base conditions (members/clips toggles)...");
      if (fetchedVideo.topicId == 'membersonly' && !channelSettings.notifyMembersOnly) {
        _logger.info('[DecisionService] ($videoId) Skipping decision: members-only video (flag disabled).');
        // No actions needed, just update seen time potentially (poller handles main companion)
        return [];
      }
      if (fetchedVideo.type == 'clip' && !channelSettings.notifyClips) {
        _logger.info('[DecisionService] ($videoId) Skipping decision: clip video (flag disabled).');
        return [];
      }

      // --- 3. Analyze State Transition ---
      _logger.debug("[DecisionService] ($videoId) Analyzing state transition...");
      final processingState = _ProcessingState(currentCacheData: cachedVideo, fetchedVideoData: fetchedVideo);

      // --- 4. Determine Actions based on Helpers Logic ---
      // Accumulate actions from helper-like logic blocks

      // Live Scheduling Logic (from _handleLiveScheduling)
      _determineLiveScheduleActions(fetchedVideo, cachedVideo, channelSettings, processingState, actions, _logger);

      // Reminder Scheduling Logic (from _handleReminderScheduling)
      await _determineReminderScheduleActions(fetchedVideo, channelSettings, processingState, reminderLeadTime, actions, _logger);

      // New Media Event Logic (from _handleNewMediaEvent)
      _determineNewMediaActions(fetchedVideo, cachedVideo, channelSettings, processingState, delayNewMedia, actions, _logger);

      // Pending New Media Trigger Logic (from _handlePendingNewMediaTrigger)
      _determinePendingNewMediaTriggerActions(fetchedVideo, cachedVideo, channelSettings, processingState, actions, _logger);

      // Live Event Logic (from _handleLiveEvent)
      _determineLiveEventActions(fetchedVideo, cachedVideo, channelSettings, processingState, currentSystemTime, actions, _logger);

      // Update Event Logic (from _handleUpdateEvent)
      _determineUpdateEventActions(fetchedVideo, cachedVideo, channelSettings, processingState, delayNewMedia, actions, _logger);

      // Mention Event Logic (from _handleMentionEvent)
      _determineMentionEventActions(
        fetchedVideo,
        cachedVideo,
        allSettings, // Pass all settings for check
        processingState,
        actions,
        _logger,
      );

      // --- 5. Final Cache Update Action ---
      // Create a single UpdateCacheAction companion reflecting the final state determined above.
      //This companion ONLY includes fields managed by the notification logic.
      final finalCacheCompanion = CachedVideosCompanion(
        // videoId will be added by the handler
        isPendingNewMediaNotification: Value(processingState.isPendingNewMedia),
        scheduledLiveNotificationId: Value(processingState.scheduledLiveNotificationId),
        scheduledReminderNotificationId: Value(processingState.scheduledReminderNotificationId),
        scheduledReminderTime: Value(processingState.scheduledReminderTime?.millisecondsSinceEpoch),
        lastLiveNotificationSentTime: Value(processingState.lastLiveNotificationSentTime?.millisecondsSinceEpoch),
      );
      actions.add(NotificationAction.updateCache(videoId: videoId, companion: finalCacheCompanion));
      _logger.debug("[DecisionService] ($videoId) Final cache update action created.");

      _logger.info("[DecisionService] ($videoId) Determined ${actions.length} actions.");
      return actions;
    } catch (e, s) {
      _logger.error("[DecisionService] ($videoId) Error determining actions for video update", e, s);
      return []; // Return empty list on error
    }
  }

  // --- Helper methods replicating _handle... logic ---

  void _determineLiveScheduleActions(
    VideoFull fetchedVideo,
    CachedVideo? cachedVideo,
    ChannelSubscriptionSetting channelSettings,
    _ProcessingState processingState,
    List<NotificationAction> actions,
    ILoggingService logger,
  ) {
    final videoId = fetchedVideo.id;
    final scheduledTime = fetchedVideo.startScheduled;
    final bool shouldBeScheduled = channelSettings.notifyLive && fetchedVideo.status == 'upcoming' && scheduledTime != null;
    final bool isCurrentlyScheduled = processingState.scheduledLiveNotificationId != null;
    final bool scheduleTimeChanged = processingState.scheduleChanged;

    if (shouldBeScheduled) {
      if (!isCurrentlyScheduled || scheduleTimeChanged) {
        logger.info(
          '[DecisionService] ($videoId) Needs Live Scheduling/Rescheduling (Current: $isCurrentlyScheduled, Changed: $scheduleTimeChanged)',
        );
        if (isCurrentlyScheduled && scheduleTimeChanged) {
          logger.debug(
            '[DecisionService] ($videoId) Adding previous Live schedule ID ${processingState.scheduledLiveNotificationId} to cancellations.',
          );
          actions.add(
            NotificationAction.cancel(
              notificationId: processingState.scheduledLiveNotificationId!,
              videoId: videoId,
              type: NotificationEventType.live,
            ),
          );
          processingState.scheduledLiveNotificationId = null; // Assume cancellation succeeds state-wise
        }
        // Add Schedule action
        final instruction = _createNotificationInstruction(fetchedVideo, NotificationEventType.live);
        actions.add(NotificationAction.schedule(instruction: instruction, scheduleTime: scheduledTime, videoId: videoId));
        // Mark state assuming schedule will succeed and handler will update cache ID
        // NOTE: We don't know the ID *yet*. The handler needs to reconcile this, or the decision service needs to provide a placeholder ID.
        // For now, we optimistically clear the ID here and the handler will hopefully set it.
        // This is a weakness - the decision service *should* ideally generate the cache update with the ID.
        // Let's assume the handler *won't* update the cache ID. The decision service *must*.
        // We *can't* know the ID here. Let's rely on optimistic state + final cache companion.
        // We'll TEMPORARILY set state ID to a placeholder like -1, then finalize in companion.
        processingState.scheduledLiveNotificationId = -1; // Placeholder indicates intent to schedule
      } else {
        logger.debug(
          '[DecisionService] ($videoId) Live Already correctly scheduled (ID: ${processingState.scheduledLiveNotificationId}). No action.',
        );
      }
    } else if (isCurrentlyScheduled) {
      logger.info(
        '[DecisionService] ($videoId) Conditions for Live scheduling no longer met. Cancelling schedule ID: ${processingState.scheduledLiveNotificationId}.',
      );
      actions.add(
        NotificationAction.cancel(notificationId: processingState.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live),
      );
      processingState.scheduledLiveNotificationId = null; // Update state
    }
  }

  Future<void> _determineReminderScheduleActions(
    VideoFull fetchedVideo,
    ChannelSubscriptionSetting channelSettings,
    _ProcessingState processingState,
    Duration reminderLeadTime,
    List<NotificationAction> actions,
    ILoggingService logger,
  ) async {
    final videoId = fetchedVideo.id;

    if (!channelSettings.notifyLive ||
        reminderLeadTime <= Duration.zero ||
        fetchedVideo.status != 'upcoming' ||
        fetchedVideo.startScheduled == null) {
      if (processingState.scheduledReminderNotificationId != null) {
        logger.info(
          '[DecisionService] ($videoId) Reminder conditions no longer met. Cancelling existing reminder ID: ${processingState.scheduledReminderNotificationId}.',
        );
        actions.add(
          NotificationAction.cancel(
            notificationId: processingState.scheduledReminderNotificationId!,
            videoId: videoId,
            type: NotificationEventType.reminder,
          ),
        );
        processingState.scheduledReminderNotificationId = null;
        processingState.scheduledReminderTime = null;
      } else {
        logger.debug("[DecisionService] ($videoId) Reminder conditions not met and no existing reminder to cancel.");
      }
      return;
    }

    final DateTime targetReminderTime = fetchedVideo.startScheduled!.subtract(reminderLeadTime);
    final DateTime now = DateTime.now();

    if (targetReminderTime.isBefore(now)) {
      logger.debug('[DecisionService] ($videoId) Calculated reminder time ($targetReminderTime) is in the past. Skipping scheduling.');
      if (processingState.scheduledReminderNotificationId != null) {
        logger.info(
          '[DecisionService] ($videoId) Calculated reminder time is past, cancelling existing reminder ID: ${processingState.scheduledReminderNotificationId}.',
        );
        actions.add(
          NotificationAction.cancel(
            notificationId: processingState.scheduledReminderNotificationId!,
            videoId: videoId,
            type: NotificationEventType.reminder,
          ),
        );
        processingState.scheduledReminderNotificationId = null;
        processingState.scheduledReminderTime = null;
      }
      return;
    }

    logger.debug("[DecisionService] ($videoId) Calculated Target Reminder Time: $targetReminderTime");

    final bool isCurrentlyScheduled = processingState.scheduledReminderNotificationId != null;
    final bool reminderTimeSignificantlyChanged =
        processingState.scheduledReminderTime == null ||
        targetReminderTime.difference(processingState.scheduledReminderTime!).abs() > const Duration(minutes: 1);

    if (!isCurrentlyScheduled || reminderTimeSignificantlyChanged) {
      logger.info(
        '[DecisionService] ($videoId) Needs Reminder Scheduling/Rescheduling (Current: $isCurrentlyScheduled, Changed: $reminderTimeSignificantlyChanged)',
      );

      if (isCurrentlyScheduled) {
        logger.debug('[DecisionService] ($videoId) Adding previous reminder ID ${processingState.scheduledReminderNotificationId} to cancellations.');
        actions.add(
          NotificationAction.cancel(
            notificationId: processingState.scheduledReminderNotificationId!,
            videoId: videoId,
            type: NotificationEventType.reminder,
          ),
        );
        processingState.scheduledReminderNotificationId = null;
        processingState.scheduledReminderTime = null;
      }

      final instruction = _createNotificationInstruction(fetchedVideo, NotificationEventType.reminder);
      actions.add(NotificationAction.schedule(instruction: instruction, scheduleTime: targetReminderTime, videoId: videoId));
      // Mark state indicating scheduling attempt
      processingState.scheduledReminderNotificationId = -1; // Placeholder
      processingState.scheduledReminderTime = targetReminderTime; // Store calculated time
    } else {
      logger.debug(
        '[DecisionService] ($videoId) Reminder already correctly scheduled (ID: ${processingState.scheduledReminderNotificationId}). No action.',
      );
      // Ensure stored time is kept
      processingState.scheduledReminderTime = processingState.scheduledReminderTime ?? targetReminderTime;
    }
  }

  void _determineNewMediaActions(
    VideoFull fetchedVideo,
    CachedVideo? cachedVideo,
    ChannelSubscriptionSetting channelSettings,
    _ProcessingState processingState,
    bool delayNewMedia,
    List<NotificationAction> actions,
    ILoggingService logger,
  ) {
    final videoId = fetchedVideo.id;
    if (!channelSettings.notifyNewMedia) return;

    final bool isPotentialNew =
        processingState.isNewVideo || (processingState.statusChanged && (cachedVideo?.status == 'missing' || fetchedVideo.status == 'new'));

    if (!isPotentialNew) return;
    logger.debug('[DecisionService] ($videoId) Potential New Media Event Detected.');

    if (delayNewMedia && !processingState.isCertain) {
      logger.info('[DecisionService] ($videoId) Delaying New Media notification (Uncertainty + Setting ON). Setting pending flag state.');
      processingState.isPendingNewMedia = true;
    } else {
      logger.info('[DecisionService] ($videoId) Dispatching New Media notification (Certainty or Setting OFF).');
      actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.newMedia)));
      processingState.isPendingNewMedia = false;
    }
  }

  void _determinePendingNewMediaTriggerActions(
    VideoFull fetchedVideo,
    CachedVideo? cachedVideo,
    ChannelSubscriptionSetting channelSettings,
    _ProcessingState processingState,
    List<NotificationAction> actions,
    ILoggingService logger,
  ) {
    final videoId = fetchedVideo.id;
    if (!processingState.wasPendingNewMedia || !channelSettings.notifyNewMedia) return;
    logger.debug('[DecisionService] ($videoId) Checking Pending New Media Trigger (wasPending=${processingState.wasPendingNewMedia}).');

    final bool triggerConditionMet =
        processingState.becameCertain || (processingState.statusChanged && fetchedVideo.status != 'upcoming' && fetchedVideo.status != 'new');

    if (triggerConditionMet) {
      logger.info('[DecisionService] ($videoId) Pending New Media condition met. Dispatching.');
      actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.newMedia)));
      processingState.isPendingNewMedia = false;
    } else {
      logger.debug('[DecisionService] ($videoId) Pending trigger conditions not met. Keeping pending state.');
      processingState.isPendingNewMedia = true;
    }
  }

  void _determineLiveEventActions(
    VideoFull fetchedVideo,
    CachedVideo? cachedVideo,
    ChannelSubscriptionSetting channelSettings,
    _ProcessingState processingState,
    DateTime currentSystemTime,
    List<NotificationAction> actions,
    ILoggingService logger,
  ) {
    final videoId = fetchedVideo.id;
    if (!channelSettings.notifyLive) return;

    final bool becameLive = processingState.statusChanged && fetchedVideo.status == 'live';
    if (!becameLive) return;

    logger.debug('[DecisionService] ($videoId) Live Event detected (Became Live).');

    const Duration debounceDuration = Duration(minutes: 2);
    DateTime? lastSentTime = processingState.lastLiveNotificationSentTime;
    bool shouldSend = true;
    if (lastSentTime != null) {
      final timeSinceLastSent = currentSystemTime.difference(lastSentTime);
      if (timeSinceLastSent < debounceDuration) {
        logger.info('[DecisionService] ($videoId) SUPPRESSING Live notification (Sent ${timeSinceLastSent.inSeconds}s ago).');
        shouldSend = false;
      }
    }

    if (shouldSend) {
      logger.info('[DecisionService] ($videoId) Dispatching immediate Live notification.');
      actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.live)));
      processingState.lastLiveNotificationSentTime = currentSystemTime; // Update state

      if (processingState.scheduledLiveNotificationId != null) {
        logger.debug(
          '[DecisionService] ($videoId) Cancelling scheduled LIVE notification ID ${processingState.scheduledLiveNotificationId} due to Live dispatch.',
        );
        actions.add(
          NotificationAction.cancel(notificationId: processingState.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live),
        );
        processingState.scheduledLiveNotificationId = null;
      }
      if (processingState.scheduledReminderNotificationId != null) {
        logger.debug(
          '[DecisionService] ($videoId) Cancelling scheduled REMINDER notification ID ${processingState.scheduledReminderNotificationId} due to Live dispatch.',
        );
        actions.add(
          NotificationAction.cancel(
            notificationId: processingState.scheduledReminderNotificationId!,
            videoId: videoId,
            type: NotificationEventType.reminder,
          ),
        );
        processingState.scheduledReminderNotificationId = null;
        processingState.scheduledReminderTime = null;
      }
    }
  }

  void _determineUpdateEventActions(
    VideoFull fetchedVideo,
    CachedVideo? cachedVideo,
    ChannelSubscriptionSetting channelSettings,
    _ProcessingState processingState,
    bool delayNewMedia,
    List<NotificationAction> actions,
    ILoggingService logger,
  ) {
    final videoId = fetchedVideo.id;
    if (!channelSettings.notifyUpdates || processingState.isNewVideo) return;

    if (processingState.scheduleChanged) {
      logger.debug('[DecisionService] ($videoId) Potential Update Event detected (Schedule Changed).');
      bool onlyCertaintyChangedWithDelay =
          processingState.becameCertain && !processingState.statusChanged && !processingState.mentionsChanged && delayNewMedia;

      if (!onlyCertaintyChangedWithDelay) {
        logger.info('[DecisionService] ($videoId) Dispatching Update notification (Schedule Changed).');
        actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.update)));
      } else {
        logger.info('[DecisionService] ($videoId) SUPPRESSING Update notification (Only certainty changed & Delay ON).');
      }
    }
  }

  void _determineMentionEventActions(
    VideoFull fetchedVideo,
    CachedVideo? cachedVideo,
    List<ChannelSubscriptionSetting> allSettings, // Pass all settings map
    _ProcessingState processingState,
    List<NotificationAction> actions,
    ILoggingService logger,
  ) {
    final videoId = fetchedVideo.id;
    if (!processingState.mentionsChanged) return;

    logger.debug('[DecisionService] ($videoId) Mention Event detected (Mention list changed).');

    final List<String> currentMentions = fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? [];
    final List<String> previousMentions = cachedVideo?.mentionedChannelIds ?? [];
    final Set<String> newMentions = Set<String>.from(currentMentions).difference(Set<String>.from(previousMentions));

    if (newMentions.isEmpty) {
      logger.debug('[DecisionService] ($videoId) Mention list changed, but no *new* mentions found.');
      return;
    }
    logger.info('[DecisionService] ($videoId) Found new mentions: ${newMentions.join(', ')}');

    final Map<String, ChannelSubscriptionSetting> settingsMap = {for (var s in allSettings) s.channelId: s};

    for (final mentionedId in newMentions) {
      final mentionTargetSettings = settingsMap[mentionedId];
      if (mentionTargetSettings != null && mentionTargetSettings.notifyMentions) {
        final mentionDetails = fetchedVideo.mentions?.firstWhereOrNull((m) => m.id == mentionedId);
        logger.info(
          '[DecisionService] ($videoId) User wants mentions for $mentionedId (${mentionDetails?.name ?? '??'}). Dispatching Mention notification.',
        );
        actions.add(
          NotificationAction.dispatch(
            instruction: _createNotificationInstruction(
              fetchedVideo,
              NotificationEventType.mention,
              mentionTargetId: mentionedId,
              mentionTargetName: mentionDetails?.name ?? 'Unknown Channel',
            ),
          ),
        );
      } else {
        logger.debug('[DecisionService] ($videoId) User DOES NOT want mentions for newly mentioned channel $mentionedId. Skipping dispatch.');
      }
    }
  }

  // --- Notification Creation Helper ---
  NotificationInstruction _createNotificationInstruction(
    VideoFull video,
    NotificationEventType type, {
    String? mentionTargetId,
    String? mentionTargetName,
  }) {
    return NotificationInstruction(
      videoId: video.id,
      eventType: type,
      channelId: video.channel.id,
      channelName: video.channel.name,
      videoTitle: video.title,
      videoType: video.type,
      channelAvatarUrl: video.channel.photo,
      availableAt: video.availableAt,
      mentionTargetChannelId: mentionTargetId,
      mentionTargetChannelName: mentionTargetName,
    );
  }

  @override
  Future<List<NotificationAction>> determineActionsForChannelSettingChange({
    required String channelId,
    required String settingKey,
    required bool oldValue,
    required bool newValue,
  }) async {
    _logger.info("[DecisionService] ($channelId) Determining actions for setting change: $settingKey ($oldValue -> $newValue)");
    final List<NotificationAction> actions = [];

    if (newValue == oldValue) {
      _logger.debug("[DecisionService] ($channelId) No change in value for $settingKey. No actions needed.");
      return [];
    }

    // --- Logic for DISABLING a setting ---
    if (!newValue) {
      if (settingKey == 'notifyLive') {
        // Cancel scheduled Live and Reminder notifications
        _logger.debug("[DecisionService] ($channelId) Disabling notifyLive. Fetching Live/Reminder notifications to cancel...");
        final List<CachedVideo> liveVids = (await _cacheService.getScheduledVideos()).where((v) => v.channelId == channelId).toList();
        final List<CachedVideo> reminderVids =
            (await _cacheService.getVideosWithScheduledReminders()).where((v) => v.channelId == channelId).toList();

        for (final video in liveVids) {
          if (video.scheduledLiveNotificationId != null) {
            actions.add(
              NotificationAction.cancel(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
            );
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null)),
              ),
            );
          }
        }
        for (final video in reminderVids) {
          if (video.scheduledReminderNotificationId != null) {
            actions.add(
              NotificationAction.cancel(
                notificationId: video.scheduledReminderNotificationId!,
                videoId: video.videoId,
                type: NotificationEventType.reminder,
              ),
            );
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
              ),
            );
          }
        }
      } else if (settingKey == 'notifyMembersOnly') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyMembersOnly. Fetching members-only videos to cancel notifications...");
        final List<CachedVideo> membersVids = await _cacheService.getMembersOnlyVideosByChannel(channelId);
        for (final video in membersVids) {
          if (video.scheduledLiveNotificationId != null) {
            actions.add(
              NotificationAction.cancel(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
            );
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null)),
              ),
            );
          }
          if (video.scheduledReminderNotificationId != null) {
            actions.add(
              NotificationAction.cancel(
                notificationId: video.scheduledReminderNotificationId!,
                videoId: video.videoId,
                type: NotificationEventType.reminder,
              ),
            );
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
              ),
            );
          }
        }
      } else if (settingKey == 'notifyClips') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyClips. Fetching clip videos to cancel notifications...");
        final List<CachedVideo> clipVids = await _cacheService.getClipVideosByChannel(channelId);
        for (final video in clipVids) {
          // Clips generally don't have Live/Reminder, but check defensively
          if (video.scheduledLiveNotificationId != null) {
            actions.add(
              NotificationAction.cancel(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
            );
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null)),
              ),
            );
          }
          if (video.scheduledReminderNotificationId != null) {
            actions.add(
              NotificationAction.cancel(
                notificationId: video.scheduledReminderNotificationId!,
                videoId: video.videoId,
                type: NotificationEventType.reminder,
              ),
            );
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
              ),
            );
          }
          // Also clear pending flag for clips if needed
          if (video.isPendingNewMediaNotification) {
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false)),
              ),
            );
          }
        }
      }
      // Add other settings disablers here if needed (e.g., notifyNewMedia might affect pending)
    }
    // --- Logic for ENABLING a setting ---
    else {
      // newValue is true
      bool needsScheduleCheck = false;
      List<CachedVideo> videosToCheck = [];

      final allCurrentSettings = await _settingsService.getChannelSubscriptions();
      final currentPersistedSetting = allCurrentSettings.firstWhereOrNull((s) => s.channelId == channelId);

      if (currentPersistedSetting == null) {
        _logger.error("[DecisionService] ($channelId) CRITICAL: Cannot find persisted settings for channel during $settingKey enable check.");
        return []; // Avoid further errors
      }
      // Determine the *current* state of notifyLive needed for scheduling checks
      bool isNotifyLiveCurrentlyEnabled = currentPersistedSetting.notifyLive;
      if (settingKey == 'notifyLive') {
        // If we are currently toggling notifyLive ON, its effective state IS true for the checks below.
        isNotifyLiveCurrentlyEnabled = true;
      }

      // Determine WHICH videos need re-evaluation based on the enabled setting
      if (settingKey == 'notifyLive') {
        _logger.debug("[DecisionService] ($channelId) Enabling notifyLive. Checking for missing schedules...");
        needsScheduleCheck = true;
        // Get all upcoming/new videos regardless of topic/type initially
        videosToCheck = await _getRelevantVideosForScheduling(channelId);
      } else if (settingKey == 'notifyMembersOnly') {
        _logger.debug("[DecisionService] ($channelId) Enabling notifyMembersOnly. Checking members-only videos for missing schedules...");
        needsScheduleCheck = true;
        // Only get members-only videos for this channel
        videosToCheck = await _cacheService.getMembersOnlyVideosByChannel(channelId);
        // Filter further for relevant statuses (upcoming/new)
        videosToCheck = videosToCheck.where((v) => v.status == 'upcoming' || v.status == 'new').toList();
      } else if (settingKey == 'notifyClips') {
        _logger.debug("[DecisionService] ($channelId) Enabling notifyClips. Checking clip videos for missing schedules...");
        // Clips typically only get scheduled if notifyLive is also on for the channel.
        final channelSetting = (await _settingsService.getChannelSubscriptions()).firstWhereOrNull((s) => s.channelId == channelId);
        if (channelSetting?.notifyLive ?? false) {
          _logger.debug("[DecisionService] ($channelId) notifyLive is also ON, checking clips.");
          needsScheduleCheck = true;
          videosToCheck = await _cacheService.getClipVideosByChannel(channelId);
          videosToCheck = videosToCheck.where((v) => v.status == 'upcoming' || v.status == 'new').toList();
        } else {
          _logger.debug(
            "[DecisionService] ($channelId) Enabled notifyClips, but notifyLive is OFF for channel. No immediate scheduling check needed.",
          );
        }
      }
      // Enabling other flags (notifyNewMedia, notifyMentions, notifyUpdates) don't require immediate scheduling.

      if (needsScheduleCheck && videosToCheck.isNotEmpty) {
        _logger.debug(
          "[DecisionService] ($channelId) Found ${videosToCheck.length} potentially relevant videos for immediate scheduling check after enabling $settingKey.",
        );
        final reminderLeadTime = await _settingsService.getReminderLeadTime();

        for (final video in videosToCheck) {
          // Always respect ALL current flags, even if only one was toggled
          // (e.g., enabling members-only shouldn't schedule if notifyLive is off)
          // Use `newValue` for the setting being changed, and persisted state for others.
          final bool checkNotifyLive = isNotifyLiveCurrentlyEnabled; // Already determined above
          final bool checkNotifyMembersOnly = (settingKey == 'notifyMembersOnly') ? newValue : currentPersistedSetting.notifyMembersOnly;
          final bool checkNotifyClips = (settingKey == 'notifyClips') ? newValue : currentPersistedSetting.notifyClips;
          // Check conditions using the EFFECTIVE state
          if (!checkNotifyLive) {
            _logger.trace("[DecisionService] ($channelId) Skipping ${video.videoId} in enable check: Effective notifyLive is OFF.");
            continue;
          }
          if (video.topicId == 'membersonly' && !checkNotifyMembersOnly) {
            _logger.trace("[DecisionService] ($channelId) Skipping ${video.videoId} in enable check: Effective notifyMembersOnly is OFF.");
            continue; // This check will now correctly use newValue if membersOnly was just enabled
          }
          if (video.videoType == 'clip' && !checkNotifyClips) {
            _logger.trace("[DecisionService] ($channelId) Skipping ${video.videoId} in enable check: Effective notifyClips is OFF.");
            continue;
          }

          // --- Scheduling Logic (Remains the same, uses effective state via checks above) ---
          final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
          if (scheduledTime == null || scheduledTime.isBefore(DateTime.now())) {
            _logger.trace("[DecisionService] ($channelId) Skipping ${video.videoId} in enable check: invalid/past schedule time.");
            continue;
          }

          // Schedule Live if missing
          if (video.scheduledLiveNotificationId == null) {
            _logger.debug(
              "[DecisionService] ($channelId) Queuing schedule action for LIVE notification on ${video.videoId} after enabling $settingKey.",
            );
            actions.add(
              NotificationAction.schedule(
                instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.live),
                scheduleTime: scheduledTime,
                videoId: video.videoId,
              ),
            );
            actions.add(
              NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(-1))),
            );
          } else {
            _logger.trace("[DecisionService] ($channelId) Skipping LIVE scheduling for ${video.videoId} in enable check: Already scheduled.");
          }

          // Schedule Reminder if missing and applicable
          if (reminderLeadTime > Duration.zero && video.scheduledReminderNotificationId == null) {
            final calculatedReminderTime = scheduledTime.subtract(reminderLeadTime);
            if (calculatedReminderTime.isAfter(DateTime.now())) {
              _logger.debug(
                "[DecisionService] ($channelId) Queuing schedule action for REMINDER notification on ${video.videoId} after enabling $settingKey.",
              );
              actions.add(
                NotificationAction.schedule(
                  instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.reminder),
                  scheduleTime: calculatedReminderTime,
                  videoId: video.videoId,
                ),
              );
              actions.add(
                NotificationAction.updateCache(
                  videoId: video.videoId,
                  companion: CachedVideosCompanion(
                    scheduledReminderNotificationId: const Value(-1),
                    scheduledReminderTime: Value(calculatedReminderTime.millisecondsSinceEpoch),
                  ),
                ),
              );
            } else {
              _logger.trace(
                "[DecisionService] ($channelId) Skipping REMINDER scheduling for ${video.videoId} in enable check: Calculated time is past.",
              );
            }
          } else if (video.scheduledReminderNotificationId != null) {
            _logger.trace("[DecisionService] ($channelId) Skipping REMINDER scheduling for ${video.videoId} in enable check: Already scheduled.");
          }
        } // End video loop
      } else if (needsScheduleCheck) {
        // If needs check == true but videosToCheck was empty
        _logger.debug("[DecisionService] ($channelId) No relevant videos found in cache for immediate scheduling check after enabling $settingKey.");
      } else {
        // If needs check == false
        _logger.debug("[DecisionService] ($channelId) Enabled $settingKey. No immediate schedule check actions generated.");
      }
    } // End else (newValue is true)

    _logger.info("[DecisionService] ($channelId/$settingKey) Determined ${actions.length} actions for setting change.");
    return actions;
  }

  Future<List<CachedVideo>> _getRelevantVideosForScheduling(String channelId) async {
    // Combine upcoming and new statuses, filter by channel
    final upcoming = await _cacheService.getVideosByStatus('upcoming');
    final news = await _cacheService.getVideosByStatus('new');
    return [...upcoming, ...news].where((v) => v.channelId == channelId).toList();
  }

  @override
  Future<List<NotificationAction>> determineActionsForApplyGlobalDefaults({
    required List<ChannelSubscriptionSetting> oldSettings,
    required List<ChannelSubscriptionSetting> newSettings,
  }) async {
    _logger.info("[DecisionService] Determining actions for applying global defaults...");
    final List<NotificationAction> allActions = [];
    final Map<String, ChannelSubscriptionSetting> oldSettingsMap = {for (var s in oldSettings) s.channelId: s};

    for (final newSetting in newSettings) {
      final oldSetting = oldSettingsMap[newSetting.channelId];
      if (oldSetting == null) continue;

      // Check each setting type for a change
      if (oldSetting.notifyLive != newSetting.notifyLive) {
        final typeActions = await determineActionsForChannelSettingChange(
          channelId: newSetting.channelId,
          settingKey: 'notifyLive',
          oldValue: oldSetting.notifyLive,
          newValue: newSetting.notifyLive,
        );
        allActions.addAll(typeActions);
      }
      if (oldSetting.notifyMembersOnly != newSetting.notifyMembersOnly) {
        final typeActions = await determineActionsForChannelSettingChange(
          channelId: newSetting.channelId,
          settingKey: 'notifyMembersOnly',
          oldValue: oldSetting.notifyMembersOnly,
          newValue: newSetting.notifyMembersOnly,
        );
        allActions.addAll(typeActions);
      }
      if (oldSetting.notifyClips != newSetting.notifyClips) {
        final typeActions = await determineActionsForChannelSettingChange(
          channelId: newSetting.channelId,
          settingKey: 'notifyClips',
          oldValue: oldSetting.notifyClips,
          newValue: newSetting.notifyClips,
        );
        allActions.addAll(typeActions);
      }
      // Add checks for notifyNewMedia, notifyMentions, notifyUpdates if they need specific enable/disable logic
    }

    _logger.info("[DecisionService] Determined ${allActions.length} actions for global defaults application.");
    return allActions;
  }

  @override
  Future<List<NotificationAction>> determineActionsForChannelRemoval({required String channelId}) async {
    _logger.info("[DecisionService] ($channelId) Determining actions for channel removal...");
    final List<NotificationAction> actions = [];

    // Find ALL scheduled notifications for this channel
    final List<CachedVideo> liveVids = (await _cacheService.getScheduledVideos()).where((v) => v.channelId == channelId).toList();
    final List<CachedVideo> reminderVids = (await _cacheService.getVideosWithScheduledReminders()).where((v) => v.channelId == channelId).toList();

    for (final video in liveVids) {
      if (video.scheduledLiveNotificationId != null) {
        actions.add(
          NotificationAction.cancel(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
        );
        // No need for cache update action here, as AppController should remove the channel entirely? Or should we clear IDs? Let's clear IDs.
        actions.add(
          NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))),
        );
      }
    }
    for (final video in reminderVids) {
      if (video.scheduledReminderNotificationId != null) {
        actions.add(
          NotificationAction.cancel(
            notificationId: video.scheduledReminderNotificationId!,
            videoId: video.videoId,
            type: NotificationEventType.reminder,
          ),
        );
        actions.add(
          NotificationAction.updateCache(
            videoId: video.videoId,
            companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
          ),
        );
      }
    }
    _logger.info("[DecisionService] ($channelId) Determined ${actions.length} cancellation actions for channel removal.");
    return actions;
  }

  @override
  Future<List<NotificationAction>> determineActionsForReminderLeadTimeChange({required Duration oldLeadTime, required Duration newLeadTime}) async {
    _logger.info("[DecisionService] Determining actions for reminder lead time change ($oldLeadTime -> $newLeadTime)");
    final List<NotificationAction> allActions = [];
    final List<ChannelSubscriptionSetting> activeChannels = (await _settingsService.getChannelSubscriptions()).where((s) => s.notifyLive).toList();

    if (activeChannels.isEmpty) {
      _logger.debug("[DecisionService] No channels active for live notifications. No reminder changes needed.");
      return [];
    }

    // Get all potentially relevant videos (upcoming/new) for ALL active channels
    // This could be optimized with a more targeted query if needed.
    final List<CachedVideo> allRelevantVideos =
        (await _cacheService.getVideosByStatus('upcoming') + await _cacheService.getVideosByStatus('new'))
            .where((v) => activeChannels.any((ch) => ch.channelId == v.channelId))
            .toList();

    for (final video in allRelevantVideos) {
      // Fetch settings again inside loop? No, assume activeChannels list is sufficient.
      final channelSetting = activeChannels.firstWhereOrNull((ch) => ch.channelId == video.channelId);
      if (channelSetting == null) continue; // Should not happen based on filter above

      // Respect other flags
      if (video.topicId == 'membersonly' && !channelSetting.notifyMembersOnly) continue;
      if (video.videoType == 'clip' && !channelSetting.notifyClips) continue;

      // Always cancel existing reminder first if it exists
      if (video.scheduledReminderNotificationId != null) {
        _logger.debug("[DecisionService] (${video.videoId}) Cancelling existing reminder due to lead time change.");
        allActions.add(
          NotificationAction.cancel(
            notificationId: video.scheduledReminderNotificationId!,
            videoId: video.videoId,
            type: NotificationEventType.reminder,
          ),
        );
        allActions.add(
          NotificationAction.updateCache(
            videoId: video.videoId,
            companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
          ),
        );
      }

      // Now try to schedule a new one if lead time > 0 and applicable
      final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
      if (newLeadTime > Duration.zero && scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        final calculatedReminderTime = scheduledTime.subtract(newLeadTime);
        if (calculatedReminderTime.isAfter(DateTime.now())) {
          _logger.debug("[DecisionService] (${video.videoId}) Scheduling new reminder with lead time ${newLeadTime.inMinutes} min.");
          allActions.add(
            NotificationAction.schedule(
              instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.reminder),
              scheduleTime: calculatedReminderTime,
              videoId: video.videoId,
            ),
          );
          // Add cache update action for the new schedule
          allActions.add(
            NotificationAction.updateCache(
              videoId: video.videoId,
              companion: CachedVideosCompanion(
                // Assume placeholder ID logic as before
                scheduledReminderNotificationId: const Value.absent(), // Rely on state/final companion
                scheduledReminderTime: Value(calculatedReminderTime.millisecondsSinceEpoch),
              ),
            ),
          );
        }
      }
    }

    _logger.info("[DecisionService] Determined ${allActions.length} actions for reminder lead time change.");
    return allActions;
  }
}

// Helper extension needed to convert CachedVideo to VideoFull for instruction creation
extension on CachedVideo {
  VideoFull toVideoFull() {
    // This requires mapping CachedVideo fields to VideoFull fields.
    // It's a simplification; VideoFull has more fields (clips, sources etc.) that aren't in cache.
    return VideoFull(
      id: videoId,
      title: videoTitle,
      type: videoType ?? 'unknown',
      topicId: topicId,
      publishedAt: null, // Not stored directly in cache
      availableAt: DateTime.parse(availableAt), // Assume parseable
      duration: 0, // Not stored in cache
      status: status,
      startScheduled: startScheduled != null ? DateTime.parse(startScheduled!) : null,
      startActual: startActual != null ? DateTime.parse(startActual!) : null,
      endActual: null, // Not stored
      liveViewers: null, // Not stored
      description: null, // Not stored
      songcount: null, // Not stored
      channel: ChannelMin(
        id: channelId,
        name: channelName,
        photo: channelAvatarUrl,
        type: 'vtuber', // Assume vtuber
      ),
      certainty: certainty,
      mentions:
          mentionedChannelIds
              .map((id) => ChannelMinWithOrg(id: id, name: 'Unknown Channel')) // Create basic mentions
              .toList(),
      // clips, sources, refers, simulcasts, songs not available from CachedVideo
    );
  }
}
