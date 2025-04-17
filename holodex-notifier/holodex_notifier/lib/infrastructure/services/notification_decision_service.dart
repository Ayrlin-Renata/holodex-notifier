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
      isCertain = (fetchedVideoData.certainty == 'certain' || fetchedVideoData.certainty == null || fetchedVideoData.type != 'placeholder'), // Treat non-placeholders as certain
      wasCertain = currentCacheData != null && (currentCacheData.certainty == 'certain' || currentCacheData.certainty == null || currentCacheData.videoType != 'placeholder'),
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
          !(currentCacheData != null && (currentCacheData.certainty == 'certain' || currentCacheData.certainty == null || currentCacheData.videoType != 'placeholder')) &&
          (fetchedVideoData.certainty == 'certain' || fetchedVideoData.certainty == null || fetchedVideoData.type != 'placeholder'), // Calculate derived state last
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
       _logger.trace("[DecisionService] ($videoId) Fetching settings..."); // More granular trace
      // Assume channel settings are passed correctly or fetched if needed.
      // Here we fetch them individually for this video's channel.
      final List<ChannelSubscriptionSetting> allSettings = await _settingsService.getChannelSubscriptions();
      final channelSettings = allSettings.firstWhereOrNull((s) => s.channelId == fetchedVideo.channel.id);

      if (channelSettings == null) {
        _logger.warning("[DecisionService] ($videoId) No settings found for channel ${fetchedVideo.channel.id}. Skipping decision logic.");
        return []; // Cannot determine actions without settings
      }
      // _logger.trace("[DecisionService] ($videoId) Fetching global settings..."); // Trace level
      final bool delayNewMedia = await _settingsService.getDelayNewMedia();
      final Duration reminderLeadTime = await _settingsService.getReminderLeadTime();

      // --- 2. Check Base Conditions ---
      _logger.trace("[DecisionService] ($videoId) Checking base conditions (members/clips)..."); // Trace level
      if (fetchedVideo.topicId == 'membersonly' && !channelSettings.notifyMembersOnly) {
        _logger.info('[DecisionService] ($videoId) Skipping decision: members-only video (flag disabled).');
        return [];
      }
      if (fetchedVideo.type == 'clip' && !channelSettings.notifyClips) {
        _logger.info('[DecisionService] ($videoId) Skipping decision: clip video (flag disabled).');
        return [];
      }

      // --- 3. Analyze State Transition ---
      _logger.trace("[DecisionService] ($videoId) Analyzing state transition..."); // Trace level
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
      await _determineMentionEventActions( // {{ Make async }}
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
        _logger.trace("[$videoId] _determineLiveScheduleActions START");
    final scheduledTime = fetchedVideo.startScheduled;
    // Schedule if Upcoming, Live enabled, AND has a future schedule time
    final bool shouldBeScheduled = channelSettings.notifyLive
        && fetchedVideo.status == 'upcoming'
        && scheduledTime != null
        && scheduledTime.isAfter(DateTime.now()); // Check if time is in the future
    final bool isCurrentlyScheduled = processingState.scheduledLiveNotificationId != null;
        // Schedule changed OR became certain (placeholder -> stream might trigger reschedule)
    final bool needsReschedule = processingState.scheduleChanged || (processingState.wasCertain == false && processingState.isCertain);


        _logger.trace("[$videoId] LiveScheduling: shouldBeScheduled=$shouldBeScheduled, isCurrentlyScheduled=$isCurrentlyScheduled, needsReschedule=$needsReschedule");

    if (shouldBeScheduled) {
      if (!isCurrentlyScheduled || needsReschedule) {
        logger.info(
          '[DecisionService] ($videoId) Needs Live Scheduling/Rescheduling (Current: $isCurrentlyScheduled, NeedsReschedule: $needsReschedule)',
        );
        if (isCurrentlyScheduled) { // Cancel only if already scheduled and needs rescheduling
          logger.debug(
            '[DecisionService] ($videoId) Adding previous Live schedule ID ${processingState.scheduledLiveNotificationId} to cancellations for reschedule.',
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
        // Add Schedule action only if scheduledTime is valid
          final instruction = _createNotificationInstruction(fetchedVideo, NotificationEventType.live);
          actions.add(NotificationAction.schedule(instruction: instruction, scheduleTime: scheduledTime, videoId: videoId));
          processingState.scheduledLiveNotificationId = -1; // Placeholder indicates intent to schedule
            } else {
        logger.debug(
          '[DecisionService] ($videoId) Live Already correctly scheduled (ID: ${processingState.scheduledLiveNotificationId}). No action.',
        );
      }
    } else if (isCurrentlyScheduled) {
      logger.info(
        '[DecisionService] ($videoId) Conditions for Live scheduling no longer met (shouldBeScheduled=false). Cancelling schedule ID: ${processingState.scheduledLiveNotificationId}.',
      );
      actions.add(
        NotificationAction.cancel(notificationId: processingState.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live),
      );
      processingState.scheduledLiveNotificationId = null; // Update state
    }
        _logger.trace("[$videoId] _determineLiveScheduleActions END");
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
        _logger.trace("[$videoId] _determineReminderScheduleActions START");


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
        logger.trace("[$videoId] Reminder conditions not met & no existing reminder."); // Trace level
      }
       _logger.trace("[$videoId] _determineReminderScheduleActions END (Conditions not met)");
      return;
    }

    final DateTime targetReminderTime = fetchedVideo.startScheduled!.subtract(reminderLeadTime);
    final DateTime now = DateTime.now();

    if (targetReminderTime.isBefore(now)) {
      logger.debug('[DecisionService] ($videoId) Calculated reminder time ($targetReminderTime) is in the past.');
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
      _logger.trace("[$videoId] _determineReminderScheduleActions END (Time in past)");
      return;
    }

     _logger.trace("[$videoId] Calculated Target Reminder Time: $targetReminderTime"); // Trace level

    final bool isCurrentlyScheduled = processingState.scheduledReminderNotificationId != null;
    // Reschedule if schedule changed OR became certain OR reminder time changed significantly
    final bool needsReschedule = processingState.scheduleChanged
                              || (processingState.wasCertain == false && processingState.isCertain)
                              || (processingState.scheduledReminderTime != null && targetReminderTime.difference(processingState.scheduledReminderTime!).abs() > const Duration(minutes: 1));

    _logger.trace("[$videoId] ReminderScheduling: isCurrentlyScheduled=$isCurrentlyScheduled, needsReschedule=$needsReschedule");


    if (!isCurrentlyScheduled || needsReschedule) {
      logger.info(
        '[DecisionService] ($videoId) Needs Reminder Scheduling/Rescheduling (Current: $isCurrentlyScheduled, NeedsReschedule: $needsReschedule)',
      );

      if (isCurrentlyScheduled) { // Cancel only if needs reschedule
        logger.debug('[DecisionService] ($videoId) Adding previous reminder ID ${processingState.scheduledReminderNotificationId} to cancellations for reschedule.');
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
     // processingState.scheduledReminderTime = processingState.scheduledReminderTime ?? targetReminderTime; // Redundant if no reschedule needed
    }
     _logger.trace("[$videoId] _determineReminderScheduleActions END");
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
     _logger.trace("[$videoId] _determineNewMediaActions START");
    if (!channelSettings.notifyNewMedia) {
       _logger.trace("[$videoId] _determineNewMediaActions END (notifyNewMedia disabled)");
       return;
    }

    // Trigger on first sight OR if status changes from 'missing' to 'new'
    final bool isPotentialNew =
        processingState.isNewVideo || (processingState.statusChanged && cachedVideo?.status == 'missing' && fetchedVideo.status == 'new');

    if (!isPotentialNew) {
        _logger.trace("[$videoId] Not a potential new media event.");
        _logger.trace("[$videoId] _determineNewMediaActions END");
        return;
    }
     _logger.trace('[DecisionService] ($videoId) Potential New Media Event Detected.'); // Trace level


    if (delayNewMedia && !processingState.isCertain) {
      logger.info('[DecisionService] ($videoId) Delaying New Media notification (Uncertainty + Setting ON). Setting pending flag.');
      processingState.isPendingNewMedia = true;
    } else {
      logger.info('[DecisionService] ($videoId) Dispatching New Media notification (Certainty or Setting OFF).');
      actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.newMedia)));
      processingState.isPendingNewMedia = false; // Clear flag if dispatched
    }
     _logger.trace("[$videoId] _determineNewMediaActions END");
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
        _logger.trace("[$videoId] _determinePendingNewMediaTriggerActions START (wasPending=${processingState.wasPendingNewMedia})");
    if (!processingState.wasPendingNewMedia || !channelSettings.notifyNewMedia) {
       _logger.trace("[$videoId] _determinePendingNewMediaTriggerActions END (conditions not met)");
       return;
    }
     // _logger.trace('[DecisionService] ($videoId) Checking Pending New Media Trigger (wasPending=${processingState.wasPendingNewMedia}).'); // Trace level

    // Trigger if it became certain OR if status changed to something other than 'upcoming' or 'new' (meaning it's now live/past/missing)
    final bool triggerConditionMet =
        processingState.becameCertain || (processingState.statusChanged && fetchedVideo.status != 'upcoming' && fetchedVideo.status != 'new');


    _logger.trace("[$videoId] Pending Trigger: becameCertain=${processingState.becameCertain}, statusChanged=${processingState.statusChanged}, newStatus=${fetchedVideo.status}, triggerConditionMet=$triggerConditionMet");

    if (triggerConditionMet) {
      logger.info('[DecisionService] ($videoId) Pending New Media condition met. Dispatching.');
      actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.newMedia)));
      processingState.isPendingNewMedia = false; // Clear pending flag
    } else {
      logger.debug('[DecisionService] ($videoId) Pending trigger conditions not met. Keeping pending state.');
      // Ensure pending flag remains true if conditions not met
      processingState.isPendingNewMedia = true;
    }
     _logger.trace("[$videoId] _determinePendingNewMediaTriggerActions END (final pending state: ${processingState.isPendingNewMedia})");
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
     _logger.trace("[$videoId] _determineLiveEventActions START");
    if (!channelSettings.notifyLive) {
       _logger.trace("[$videoId] _determineLiveEventActions END (notifyLive disabled)");
       return;
    }

    final bool becameLive = processingState.statusChanged && fetchedVideo.status == 'live';
    if (!becameLive) {
       _logger.trace("[$videoId] _determineLiveEventActions END (did not become live)");
       return;
    }

     _logger.trace('[DecisionService] ($videoId) Live Event detected (Became Live).'); // Trace level

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
     _logger.trace("[$videoId] _determineLiveEventActions END");
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
     _logger.trace("[$videoId] _determineUpdateEventActions START");
    if (!channelSettings.notifyUpdates || processingState.isNewVideo) {
       _logger.trace("[$videoId] _determineUpdateEventActions END (notifyUpdates disabled or isNewVideo)");
       return;
    }

    bool significativeUpdate = processingState.scheduleChanged || processingState.statusChanged; // Basic check

    if (significativeUpdate) {
       _logger.trace('[DecisionService] ($videoId) Potential Update Event detected (Schedule/Status Changed).'); // Trace level
      // Avoid sending Update if the *only* reason was becoming certain AND delayNewMedia is on (NewMedia notification handles it)
      bool onlyCertaintyChangedWithDelay =
          processingState.becameCertain
           && !processingState.statusChanged
           && !processingState.mentionsChanged
           && !processingState.scheduleChanged // Make sure schedule didn't *also* change
           && delayNewMedia;

        _logger.trace("[$videoId] Update Check: significativeUpdate=$significativeUpdate, onlyCertaintyChangedWithDelay=$onlyCertaintyChangedWithDelay");


      if (!onlyCertaintyChangedWithDelay) {
        logger.info('[DecisionService] ($videoId) Dispatching Update notification.');
        actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.update)));
      } else {
        logger.info('[DecisionService] ($videoId) SUPPRESSING Update notification (Only certainty changed & Delay ON).');
      }
    }
     _logger.trace("[$videoId] _determineUpdateEventActions END");
  }

  Future<void> _determineMentionEventActions( // {{ Must be async due to settings fetch }}
    VideoFull fetchedVideo,
    CachedVideo? cachedVideo,
    List<ChannelSubscriptionSetting> allSettings, // Pass all settings map
    _ProcessingState processingState,
    List<NotificationAction> actions,
    ILoggingService logger,
  ) async {
    final videoId = fetchedVideo.id;
     _logger.trace("[$videoId] _determineMentionEventActions START");
    if (!processingState.mentionsChanged) {
       _logger.trace("[$videoId] _determineMentionEventActions END (mentions did not change)");
       return;
    }

     _logger.trace('[DecisionService] ($videoId) Mention Event detected (Mention list changed).'); // Trace level


    final List<String> currentMentions = fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? [];
    final List<String> previousMentions = cachedVideo?.mentionedChannelIds ?? [];
    final Set<String> newMentions = Set<String>.from(currentMentions).difference(Set<String>.from(previousMentions));

    if (newMentions.isEmpty) {
      logger.debug('[DecisionService] ($videoId) Mention list changed, but no *new* mentions found.');
       _logger.trace("[$videoId] _determineMentionEventActions END (no new mentions)");
      return;
    }
    logger.info('[DecisionService] ($videoId) Found new mentions: ${newMentions.join(', ')}');

    final Map<String, ChannelSubscriptionSetting> settingsMap = {for (var s in allSettings) s.channelId: s};

    for (final mentionedId in newMentions) {
      final mentionTargetSettings = settingsMap[mentionedId]; // Use map lookup
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
     _logger.trace("[$videoId] _determineMentionEventActions END");
  }


  // --- Notification Creation Helper ---
  NotificationInstruction _createNotificationInstruction(
    VideoFull video,
    NotificationEventType type, {
    String? mentionTargetId,
    String? mentionTargetName,
  }) {
    // {{ Derive thumbnail URL and source link }}
    String? thumbnailUrl;
    String? sourceLink;

    if (video.type == 'placeholder' && video.thumbnail != null && video.thumbnail!.isNotEmpty) {
        thumbnailUrl = video.thumbnail; // Use placeholder specific thumbnail
        if (video.link != null && video.link!.isNotEmpty) {
           sourceLink = video.link; // Use placeholder specific link
        }
    } else {
        // Standard YouTube thumbnail URL format
        thumbnailUrl = 'https://i.ytimg.com/vi/${video.id}/mqdefault.jpg';
        // Source link for non-placeholders defaults to null (handled by buttons)
    }


    return NotificationInstruction(
      videoId: video.id,
      eventType: type,
      channelId: video.channel.id,
      channelName: video.channel.name,
      videoTitle: video.title,
      videoType: video.type,
      channelAvatarUrl: video.channel.photo,
      availableAt: video.availableAt, // Required field
      mentionTargetChannelId: mentionTargetId,
      mentionTargetChannelName: mentionTargetName,
      // {{ Populate new fields }}
      videoThumbnailUrl: thumbnailUrl,
      videoSourceLink: sourceLink,
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
        // Use combined query and filter locally for efficiency
        final List<CachedVideo> scheduledVids = (await _cacheService.getScheduledVideos())
                                                .where((v) => v.channelId == channelId).toList();

        for (final video in scheduledVids) {
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
             // Clear pending flag if it's a members-only video being disabled
          if (video.isPendingNewMediaNotification) {
             actions.add(NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
              _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to disabled members-only.");
          }
        }
      } else if (settingKey == 'notifyClips') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyClips. Fetching clip videos to cancel notifications/clear pending...");
        final List<CachedVideo> clipVids = await _cacheService.getClipVideosByChannel(channelId);
        for (final video in clipVids) {
          // Clips generally don't have scheduled notifications, but clear pending flag
          if (video.isPendingNewMediaNotification) {
             actions.add(NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
              _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to disabled clips.");
          }
           // Defensive cancellation (unlikely but safe)
           if (video.scheduledLiveNotificationId != null) actions.add(NotificationAction.cancel(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live));
           if (video.scheduledReminderNotificationId != null) actions.add(NotificationAction.cancel(notificationId: video.scheduledReminderNotificationId!, videoId: video.videoId, type: NotificationEventType.reminder));
        }
      } else if (settingKey == 'notifyNewMedia'){
         // If disabling new media, find pending videos for this channel and clear the flag
           _logger.debug("[DecisionService] ($channelId) Disabling notifyNewMedia. Checking for pending videos to clear flag...");
             final List<CachedVideo> potentiallyPending = (await _cacheService.getVideosByStatus('new') + await _cacheService.getVideosByStatus('upcoming'))
                                                         .where((v) => v.channelId == channelId && v.isPendingNewMediaNotification).toList();
            for (final video in potentiallyPending) {
                 actions.add(NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
                 _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to disabled notifyNewMedia.");
            }
      }
      // Add other settings disablers here if needed (e.g., notifyMentions doesn't need cleanup)
    }
    // --- Logic for ENABLING a setting ---
    else { // newValue is true
      bool needsScheduleCheck = false;
      List<CachedVideo> videosToCheck = [];

      // --- Determine the 'effective' state of all relevant flags ---
      // This avoids repeated lookups and handles the currently changing flag
      final allCurrentSettings = await _settingsService.getChannelSubscriptions();
      final currentPersistedSetting = allCurrentSettings.firstWhereOrNull((s) => s.channelId == channelId);

      if (currentPersistedSetting == null) {
        _logger.error("[DecisionService] ($channelId) CRITICAL: Cannot find persisted settings for channel during $settingKey enable check.");
        return []; // Avoid further errors
      }
      // Calculate the EFFECTIVE state *after* this change
      final effectiveSetting = currentPersistedSetting.copyWith(
          notifyLive: (settingKey == 'notifyLive') ? newValue : currentPersistedSetting.notifyLive,
          notifyMembersOnly: (settingKey == 'notifyMembersOnly') ? newValue : currentPersistedSetting.notifyMembersOnly,
          notifyClips: (settingKey == 'notifyClips') ? newValue : currentPersistedSetting.notifyClips,
          // Include others if needed
      );

      // Determine WHICH videos need re-evaluation based on the enabled setting
      if (settingKey == 'notifyLive' || settingKey == 'notifyMembersOnly' || settingKey == 'notifyClips') {
            _logger.debug("[DecisionService] ($channelId) Enabling $settingKey. Checking for missing schedules...");
            needsScheduleCheck = true;
            // Get all upcoming videos for the channel (including members/clips)
            videosToCheck = (await _cacheService.getVideosByStatus('upcoming'))
               .where((v) => v.channelId == channelId)
               .toList();
      }
      // Enabling other flags (notifyNewMedia, notifyMentions, notifyUpdates) don't usually require immediate scheduling.


      if (needsScheduleCheck && videosToCheck.isNotEmpty) {
        _logger.debug("[DecisionService] ($channelId) Found ${videosToCheck.length} potentially relevant videos for immediate scheduling check after enabling $settingKey.");
        final reminderLeadTime = await _settingsService.getReminderLeadTime();

        for (final video in videosToCheck) {
          // Check conditions using the EFFECTIVE state
          if (!effectiveSetting.notifyLive) {
            _logger.trace("[DecisionService] ($channelId) Skipping ${video.videoId} in enable check: Effective notifyLive is OFF.");
            continue;
          }
          if (video.topicId == 'membersonly' && !effectiveSetting.notifyMembersOnly) {
             _logger.trace("[DecisionService] ($channelId) Skipping ${video.videoId} in enable check: Effective notifyMembersOnly is OFF.");
            continue;
          }
          if (video.videoType == 'clip' && !effectiveSetting.notifyClips) {
             _logger.trace("[DecisionService] ($channelId) Skipping ${video.videoId} in enable check: Effective notifyClips is OFF.");
            continue;
          }

          // --- Scheduling Logic ---
          final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
           // Check only future schedules
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
              NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(-1))), // Placeholder
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
                    scheduledReminderNotificationId: const Value(-1), // Placeholder
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
        _logger.debug("[DecisionService] ($channelId) No relevant videos found in cache for immediate scheduling check after enabling $settingKey.");
      } else {
        _logger.debug("[DecisionService] ($channelId) Enabled $settingKey. No immediate schedule check actions generated.");
      }
    } // End else (newValue is true)


    _logger.info("[DecisionService] ($channelId/$settingKey) Determined ${actions.length} actions for setting change.");
    return actions;
  }

  // ... other methods (determineActionsForApplyGlobalDefaults, determineActionsForChannelRemoval, determineActionsForReminderLeadTimeChange) remain the same.

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
      if (oldSetting == null) continue; // Should not happen if list comes from same provider

      // Check each setting type for a change and call the specific handler
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
       if (oldSetting.notifyNewMedia != newSetting.notifyNewMedia) {
        final typeActions = await determineActionsForChannelSettingChange(
          channelId: newSetting.channelId,
          settingKey: 'notifyNewMedia',
          oldValue: oldSetting.notifyNewMedia,
          newValue: newSetting.notifyNewMedia,
        );
        allActions.addAll(typeActions);
      }
       if (oldSetting.notifyUpdates != newSetting.notifyUpdates) {
        final typeActions = await determineActionsForChannelSettingChange(
          channelId: newSetting.channelId,
          settingKey: 'notifyUpdates',
          oldValue: oldSetting.notifyUpdates,
          newValue: newSetting.notifyUpdates,
        );
        allActions.addAll(typeActions);
      }
       if (oldSetting.notifyMentions != newSetting.notifyMentions) {
         // Mentions usually don't require cleanup/reschedule, but check just in case
        final typeActions = await determineActionsForChannelSettingChange(
          channelId: newSetting.channelId,
          settingKey: 'notifyMentions',
          oldValue: oldSetting.notifyMentions,
          newValue: newSetting.notifyMentions,
        );
        allActions.addAll(typeActions);
      }
    }

    _logger.info("[DecisionService] Determined ${allActions.length} actions for global defaults application.");
    return allActions;
  }

  @override
  Future<List<NotificationAction>> determineActionsForChannelRemoval({required String channelId}) async {
    _logger.info("[DecisionService] ($channelId) Determining actions for channel removal...");
    final List<NotificationAction> actions = [];

    // Find ALL scheduled notifications for this channel
    final List<CachedVideo> scheduledVids = (await _cacheService.getScheduledVideos())
                                           .where((v) => v.channelId == channelId).toList();

    for (final video in scheduledVids) {
      // Cancel Live notification if scheduled
      if (video.scheduledLiveNotificationId != null) {
        actions.add(
          NotificationAction.cancel(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
        );
        // Clear the ID in the cache (the record itself might be deleted later or kept for history)
        actions.add(
          NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))),
        );
      }
       // Cancel Reminder notification if scheduled
      if (video.scheduledReminderNotificationId != null) {
        actions.add(
          NotificationAction.cancel(
            notificationId: video.scheduledReminderNotificationId!,
            videoId: video.videoId,
            type: NotificationEventType.reminder,
          ),
        );
        // Clear reminder ID and time in cache
        actions.add(
          NotificationAction.updateCache(
            videoId: video.videoId,
            companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
          ),
        );
      }
    }
    // Additionally, clear any pending flags for videos of this channel?
    // Fetch 'new' and 'upcoming' videos for the channel being removed
    final List<CachedVideo> potentialPending = (await _cacheService.getVideosByStatus('new') + await _cacheService.getVideosByStatus('upcoming'))
                                                .where((v) => v.channelId == channelId && v.isPendingNewMediaNotification)
                                                .toList();
     for (final video in potentialPending) {
         actions.add(NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
         _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to channel removal.");
     }


    _logger.info("[DecisionService] ($channelId) Determined ${actions.length} cancellation/cleanup actions for channel removal.");
    return actions;
  }

 @override
  Future<List<NotificationAction>> determineActionsForReminderLeadTimeChange({required Duration oldLeadTime, required Duration newLeadTime}) async {
    _logger.info("[DecisionService] Determining actions for reminder lead time change ($oldLeadTime -> $newLeadTime)");
    final List<NotificationAction> allActions = [];
    final List<ChannelSubscriptionSetting> activeChannels = (await _settingsService.getChannelSubscriptions())
                                                            .where((s) => s.notifyLive).toList(); // Only channels wanting live notifications

    if (activeChannels.isEmpty) {
      _logger.debug("[DecisionService] No channels active for live notifications. No reminder changes needed.");
      return [];
    }

    // Get all potentially relevant videos (upcoming only for reminders) for ALL active channels
    final List<CachedVideo> allUpcomingVideos = (await _cacheService.getVideosByStatus('upcoming'))
                                                  .where((v) => activeChannels.any((ch) => ch.channelId == v.channelId))
                                                  .toList();

    _logger.debug("[DecisionService] Found ${allUpcomingVideos.length} upcoming videos for channels with notifyLive enabled.");

    for (final video in allUpcomingVideos) {
      // Find the specific setting for this video's channel
      final channelSetting = activeChannels.firstWhereOrNull((ch) => ch.channelId == video.channelId);
      if (channelSetting == null) continue; // Should not happen based on filter above

      // Respect other flags
      if (video.topicId == 'membersonly' && !channelSetting.notifyMembersOnly) continue;
      if (video.videoType == 'clip' && !channelSetting.notifyClips) continue;

       _logger.trace("[DecisionService] (${video.videoId}) Processing for reminder lead time change.");

      // Always cancel existing reminder first if it exists
      // This simplifies logic: always cancel, then reschedule if needed
      if (video.scheduledReminderNotificationId != null) {
        _logger.debug("[DecisionService] (${video.videoId}) Cancelling existing reminder ID ${video.scheduledReminderNotificationId} due to lead time change.");
        allActions.add(
          NotificationAction.cancel(
            notificationId: video.scheduledReminderNotificationId!,
            videoId: video.videoId,
            type: NotificationEventType.reminder,
          ),
        );
        // Add Cache action to clear the ID/Time immediately after cancellation action
        allActions.add(
          NotificationAction.updateCache(
            videoId: video.videoId,
            companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
          ),
        );
      }

      // Now try to schedule a new one if lead time > 0 and video is applicable
      final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
      if (newLeadTime > Duration.zero && scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        final calculatedReminderTime = scheduledTime.subtract(newLeadTime);
        if (calculatedReminderTime.isAfter(DateTime.now())) {
          _logger.debug("[DecisionService] (${video.videoId}) Scheduling new reminder for $calculatedReminderTime with lead time ${newLeadTime.inMinutes} min.");
          allActions.add(
            NotificationAction.schedule(
              instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.reminder),
              scheduleTime: calculatedReminderTime,
              videoId: video.videoId,
            ),
          );
          // Add cache update action for the new schedule placeholder
          allActions.add(
            NotificationAction.updateCache(
              videoId: video.videoId,
              companion: CachedVideosCompanion(
                 scheduledReminderNotificationId: const Value(-1), // Placeholder
                 scheduledReminderTime: Value(calculatedReminderTime.millisecondsSinceEpoch),
              ),
            ),
          );
        } else {
           _logger.trace("[DecisionService] (${video.videoId}) New calculated reminder time $calculatedReminderTime is in the past. Not scheduling.");
        }
      } else {
         _logger.trace("[DecisionService] (${video.videoId}) Not scheduling new reminder (lead time zero or video not applicable).");
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
     DateTime? tryParseDateTime(String? iso) => iso == null ? null : DateTime.tryParse(iso);
     DateTime parseDateTimeReq(String iso) => DateTime.parse(iso);


    return VideoFull(
      id: videoId,
      title: videoTitle,
      type: videoType ?? 'unknown',
      topicId: topicId,
      publishedAt: null, // Not stored directly in cache
      availableAt: parseDateTimeReq(availableAt), // Assume parseable
      duration: 0, // Not stored in cache
      status: status,
      startScheduled: tryParseDateTime(startScheduled),
      startActual: tryParseDateTime(startActual),
      endActual: null, // Not stored
      liveViewers: null, // Not stored
      description: null, // Not stored
      songcount: null, // Not stored
      channel: ChannelMin(
        id: channelId,
        name: channelName,
        photo: channelAvatarUrl,
        type: 'vtuber', // Assume vtuber // TODO: maybe store type in cache?
      ),
      certainty: certainty,
       thumbnail: null, // Not explicitly stored in cache, could try to derive but not reliable
       link: null, // Not stored in cache
      mentions:
          mentionedChannelIds
              .map((id) => ChannelMinWithOrg(id: id, name: 'Unknown Channel')) // Create basic mentions
              .toList(),
      // clips, sources, refers, simulcasts, songs not available from CachedVideo
    );
  }
}
