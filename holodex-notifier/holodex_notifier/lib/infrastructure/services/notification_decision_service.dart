import 'dart:async';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
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

class _ProcessingState {
  int? scheduledLiveNotificationId;
  int? scheduledReminderNotificationId;
  DateTime? scheduledReminderTime;
  bool isPendingNewMedia = false;
  DateTime? lastLiveNotificationSentTime;

  final bool isNewVideo;
  final bool isCertain;
  final bool wasCertain;
  final bool statusChanged;
  final bool scheduleChanged;
  final bool becameCertain;
  final bool mentionsChanged;
  final bool wasPendingNewMedia;
  final bool reminderTimeChanged;

  _ProcessingState({required CachedVideo? currentCacheData, required VideoFull fetchedVideoData})
    : isNewVideo = currentCacheData == null,
      isCertain = (fetchedVideoData.certainty == 'certain' || fetchedVideoData.certainty == null || fetchedVideoData.type != 'placeholder'),
      wasCertain =
          currentCacheData != null &&
          (currentCacheData.certainty == 'certain' || currentCacheData.certainty == null || currentCacheData.videoType != 'placeholder'),
      statusChanged = currentCacheData != null && currentCacheData.status != fetchedVideoData.status,
      scheduleChanged = currentCacheData != null && currentCacheData.startScheduled != fetchedVideoData.startScheduled?.toIso8601String(),
      mentionsChanged =
          currentCacheData != null &&
          !const ListEquality().equals(
            currentCacheData.mentionedChannelIds,
            fetchedVideoData.mentions?.map((m) => m.id).whereType<String>().toList() ?? [],
          ),
      wasPendingNewMedia = currentCacheData?.isPendingNewMediaNotification ?? false,
      becameCertain =
          !(currentCacheData != null &&
              (currentCacheData.certainty == 'certain' || currentCacheData.certainty == null || currentCacheData.videoType != 'placeholder')) &&
          (fetchedVideoData.certainty == 'certain' || fetchedVideoData.certainty == null || fetchedVideoData.type != 'placeholder'),
      reminderTimeChanged =
          currentCacheData?.scheduledReminderTime != null && currentCacheData!.startScheduled != fetchedVideoData.startScheduled?.toIso8601String() {
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

class NotificationDecisionService implements INotificationDecisionService {
  final ICacheService _cacheService;
  final ISettingsService _settingsService;
  final ILoggingService _logger;

  NotificationDecisionService(this._cacheService, this._settingsService, this._logger);

  @override
  Future<List<NotificationAction>> determineActionsForVideoUpdate({required VideoFull fetchedVideo, required CachedVideo? cachedVideo}) async {
    final String videoId = fetchedVideo.id;
    final List<NotificationAction> actions = [];
    final DateTime currentSystemTime = DateTime.now();
    _logger.debug("[DecisionService] ($videoId) Determining actions for video update...");

    try {
      _logger.trace("[DecisionService] ($videoId) Fetching settings...");
      final List<ChannelSubscriptionSetting> allSettings = await _settingsService.getChannelSubscriptions();
      final channelSettings = allSettings.firstWhereOrNull((s) => s.channelId == fetchedVideo.channel.id);

      if (channelSettings == null) {
        _logger.warning("[DecisionService] ($videoId) No settings found for channel ${fetchedVideo.channel.id}. Skipping decision logic.");
        return [];
      }
      final bool delayNewMedia = await _settingsService.getDelayNewMedia();
      final Duration reminderLeadTime = await _settingsService.getReminderLeadTime();

      _logger.trace("[DecisionService] ($videoId) Checking base conditions (members/clips)...");
      if (fetchedVideo.topicId == 'membersonly' && !channelSettings.notifyMembersOnly) {
        _logger.info('[DecisionService] ($videoId) Skipping decision: members-only video (flag disabled).');
        return [];
      }
      if (fetchedVideo.type == 'clip' && !channelSettings.notifyClips) {
        _logger.info('[DecisionService] ($videoId) Skipping decision: clip video (flag disabled).');
        return [];
      }

      _logger.trace("[DecisionService] ($videoId) Analyzing state transition...");
      final processingState = _ProcessingState(currentCacheData: cachedVideo, fetchedVideoData: fetchedVideo);

      final dismissedTimestamp = cachedVideo?.userDismissedAt;
      bool dismissed = false;
      if (dismissedTimestamp != null) {
        dismissed = true;
        final dismissedAt = DateTime.fromMillisecondsSinceEpoch(dismissedTimestamp);
        _logger.info(
          "[DecisionService] ($videoId) Video was dismissed (${currentSystemTime.difference(dismissedAt).inSeconds}s ago). Suppressing *some* immediate dispatches.",
        );
      }

      _determineLiveScheduleActions(fetchedVideo, cachedVideo, channelSettings, processingState, actions, _logger);
      await _determineReminderScheduleActions(fetchedVideo, channelSettings, processingState, reminderLeadTime, actions, _logger);
      _determineNewMediaActions(fetchedVideo, cachedVideo, channelSettings, processingState, delayNewMedia, actions, _logger, dismissed);
      _determinePendingNewMediaTriggerActions(fetchedVideo, cachedVideo, channelSettings, processingState, actions, _logger, dismissed);
      _determineLiveEventActions(fetchedVideo, cachedVideo, channelSettings, processingState, currentSystemTime, actions, _logger, dismissed);
      _determineUpdateEventActions(fetchedVideo, cachedVideo, channelSettings, processingState, delayNewMedia, actions, _logger, dismissed);
      await _determineMentionEventActions(fetchedVideo, cachedVideo, allSettings, processingState, actions, _logger, dismissed);

      Value<int?> userDismissedValue = const Value.absent();
      if (dismissedTimestamp != null && !dismissed) {
        userDismissedValue = const Value(null);
        _logger.debug("[DecisionService] ($videoId) Adding cache action to clear old userDismissedAt timestamp.");
      }

      final finalCacheCompanion = CachedVideosCompanion(
        isPendingNewMediaNotification: Value(processingState.isPendingNewMedia),
        scheduledLiveNotificationId: Value(processingState.scheduledLiveNotificationId),
        scheduledReminderNotificationId: Value(processingState.scheduledReminderNotificationId),
        scheduledReminderTime: Value(processingState.scheduledReminderTime?.millisecondsSinceEpoch),
        lastLiveNotificationSentTime: Value(processingState.lastLiveNotificationSentTime?.millisecondsSinceEpoch),
        userDismissedAt: userDismissedValue,
      );
      final existingCacheUpdateIndex = actions.indexWhere((a) => a is UpdateCacheAction && a.videoId == videoId);
      if (existingCacheUpdateIndex != -1) {
        final existingAction = actions[existingCacheUpdateIndex] as UpdateCacheAction;
        actions[existingCacheUpdateIndex] = UpdateCacheAction(
          videoId: videoId,
          companion: existingAction.companion.copyWith(
            isPendingNewMediaNotification: finalCacheCompanion.isPendingNewMediaNotification,
            scheduledLiveNotificationId: finalCacheCompanion.scheduledLiveNotificationId,
            scheduledReminderNotificationId: finalCacheCompanion.scheduledReminderNotificationId,
            scheduledReminderTime: finalCacheCompanion.scheduledReminderTime,
            lastLiveNotificationSentTime: finalCacheCompanion.lastLiveNotificationSentTime,
            userDismissedAt: finalCacheCompanion.userDismissedAt,
          ),
        );
        _logger.debug("[DecisionService] ($videoId) Merged final cache state into existing update action.");
      } else {
        actions.add(NotificationAction.updateCache(videoId: videoId, companion: finalCacheCompanion));
        _logger.debug("[DecisionService] ($videoId) Added final cache update action.");
      }

      _logger.info("[DecisionService] ($videoId) Determined ${actions.length} actions.");
      return actions;
    } catch (e, s) {
      _logger.error("[DecisionService] ($videoId) Error determining actions for video update", e, s);
      return [];
    }
  }

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
    final bool shouldBeScheduled =
        channelSettings.notifyLive && fetchedVideo.status == 'upcoming' && scheduledTime != null && scheduledTime.isAfter(DateTime.now());
    final bool isCurrentlyScheduled = processingState.scheduledLiveNotificationId != null;
    final bool needsReschedule = processingState.scheduleChanged || (processingState.wasCertain == false && processingState.isCertain);

    _logger.trace(
      "[$videoId] LiveScheduling: shouldBeScheduled=$shouldBeScheduled, isCurrentlyScheduled=$isCurrentlyScheduled, needsReschedule=$needsReschedule (scheduleChanged=${processingState.scheduleChanged}, becameCertain=${processingState.becameCertain})",
    );

    if (shouldBeScheduled) {
      if (!isCurrentlyScheduled || needsReschedule) {
        logger.info(
          '[DecisionService] ($videoId) Needs Live Scheduling/Rescheduling (Current: $isCurrentlyScheduled, NeedsReschedule: $needsReschedule)',
        );
        if (needsReschedule && processingState.scheduleChanged) {
          logger.info('[DecisionService] ($videoId) Rescheduling LIVE notification due to schedule change.');
        }
        if (isCurrentlyScheduled) {
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
          processingState.scheduledLiveNotificationId = null;
        }
        final instruction = _createNotificationInstruction(fetchedVideo, NotificationEventType.live);
        actions.add(NotificationAction.schedule(instruction: instruction, scheduleTime: scheduledTime, videoId: videoId));
        processingState.scheduledLiveNotificationId = -1;
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
      processingState.scheduledLiveNotificationId = null;
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
        logger.trace("[$videoId] Reminder conditions not met & no existing reminder.");
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

    _logger.trace("[$videoId] Calculated Target Reminder Time: $targetReminderTime");

    final bool isCurrentlyScheduled = processingState.scheduledReminderNotificationId != null;
    final bool needsReschedule =
        processingState.scheduleChanged ||
        (processingState.wasCertain == false && processingState.isCertain) ||
        (processingState.scheduledReminderTime != null &&
            targetReminderTime.difference(processingState.scheduledReminderTime!).abs() > const Duration(minutes: 1));

    _logger.trace(
      "[$videoId] ReminderScheduling: isCurrentlyScheduled=$isCurrentlyScheduled, needsReschedule=$needsReschedule (scheduleChanged=${processingState.scheduleChanged}, becameCertain=${processingState.becameCertain}, reminderTimeChanged=${processingState.reminderTimeChanged})",
    );

    if (!isCurrentlyScheduled || needsReschedule) {
      logger.info(
        '[DecisionService] ($videoId) Needs Reminder Scheduling/Rescheduling (Current: $isCurrentlyScheduled, NeedsReschedule: $needsReschedule)',
      );
      if (needsReschedule && processingState.scheduleChanged) {
        logger.info('[DecisionService] ($videoId) Rescheduling REMINDER notification due to schedule change.');
      }

      if (isCurrentlyScheduled) {
        logger.debug(
          '[DecisionService] ($videoId) Adding previous reminder ID ${processingState.scheduledReminderNotificationId} to cancellations for reschedule.',
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

      final instruction = _createNotificationInstruction(fetchedVideo, NotificationEventType.reminder);
      actions.add(NotificationAction.schedule(instruction: instruction, scheduleTime: targetReminderTime, videoId: videoId));
      processingState.scheduledReminderNotificationId = -1;
      processingState.scheduledReminderTime = targetReminderTime;
    } else {
      logger.debug(
        '[DecisionService] ($videoId) Reminder already correctly scheduled (ID: ${processingState.scheduledReminderNotificationId}). No action.',
      );
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
    bool recentlyDismissed,
  ) {
    final videoId = fetchedVideo.id;
    _logger.trace("[$videoId] _determineNewMediaActions START");
    if (!channelSettings.notifyNewMedia) {
      _logger.trace("[$videoId] _determineNewMediaActions END (notifyNewMedia disabled)");
      return;
    }

    final bool isPotentialNew =
        processingState.isNewVideo || (processingState.statusChanged && cachedVideo?.status == 'missing' && fetchedVideo.status == 'new');

    if (!isPotentialNew) {
      _logger.trace("[$videoId] Not a potential new media event.");
      _logger.trace("[$videoId] _determineNewMediaActions END");
      return;
    }
    _logger.trace('[DecisionService] ($videoId) Potential New Media Event Detected.');

    if (recentlyDismissed && !processingState.isCertain) {
      logger.info('[DecisionService] ($videoId) Suppressing potential New Media dispatch (Uncertain + Recently Dismissed). Keeping pending flag.');
      processingState.isPendingNewMedia = true;
    } else if (delayNewMedia && !processingState.isCertain) {
      logger.info('[DecisionService] ($videoId) Delaying New Media notification (Uncertainty + Setting ON). Setting pending flag.');
      processingState.isPendingNewMedia = true;
    } else if (recentlyDismissed) {
      logger.info('[DecisionService] ($videoId) Suppressing New Media dispatch (Recently Dismissed).');
      processingState.isPendingNewMedia = false;
    } else {
      logger.info('[DecisionService] ($videoId) Dispatching New Media notification (Certainty or Setting OFF, Not Recently Dismissed).');
      actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.newMedia)));
      processingState.isPendingNewMedia = false;
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
    bool recentlyDismissed,
  ) {
    final videoId = fetchedVideo.id;
    _logger.trace("[$videoId] _determinePendingNewMediaTriggerActions START (wasPending=${processingState.wasPendingNewMedia})");
    if (!processingState.wasPendingNewMedia || !channelSettings.notifyNewMedia) {
      _logger.trace("[$videoId] _determinePendingNewMediaTriggerActions END (conditions not met)");
      return;
    }

    final bool triggerConditionMet =
        processingState.becameCertain || (processingState.statusChanged && fetchedVideo.status != 'upcoming' && fetchedVideo.status != 'new');

    _logger.trace(
      "[$videoId] Pending Trigger: becameCertain=${processingState.becameCertain}, statusChanged=${processingState.statusChanged}, newStatus=${fetchedVideo.status}, triggerConditionMet=$triggerConditionMet",
    );

    if (triggerConditionMet) {
      if (recentlyDismissed) {
        logger.info('[DecisionService] ($videoId) Suppressing Pending New Media dispatch (Recently Dismissed). Clearing pending flag.');
        processingState.isPendingNewMedia = false;
      } else {
        logger.info('[DecisionService] ($videoId) Pending New Media condition met. Dispatching.');
        actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.newMedia)));
        processingState.isPendingNewMedia = false;
      }
    } else {
      logger.debug('[DecisionService] ($videoId) Pending trigger conditions not met. Keeping pending state.');
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
    bool recentlyDismissed,
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

    _logger.trace('[DecisionService] ($videoId) Live Event detected (Became Live).');

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
      if (recentlyDismissed) {
        logger.info('[DecisionService] ($videoId) SUPPRESSING Live notification (Recently Dismissed).');
      } else {
        logger.info('[DecisionService] ($videoId) Dispatching immediate Live notification.');
        actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.live)));
        processingState.lastLiveNotificationSentTime = currentSystemTime;
        actions.add(NotificationAction.updateCache(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));

        if (processingState.scheduledLiveNotificationId != null) {
          logger.debug(
            '[DecisionService] ($videoId) Cancelling scheduled LIVE notification ID ${processingState.scheduledLiveNotificationId} due to Live dispatch.',
          );
          actions.add(
            NotificationAction.cancel(
              notificationId: processingState.scheduledLiveNotificationId!,
              videoId: videoId,
              type: NotificationEventType.live,
            ),
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
    bool recentlyDismissed,
  ) {
    final videoId = fetchedVideo.id;
    _logger.trace("[$videoId] _determineUpdateEventActions START");
    if (!channelSettings.notifyUpdates || processingState.isNewVideo) {
      _logger.trace("[$videoId] _determineUpdateEventActions END (notifyUpdates disabled or isNewVideo)");
      return;
    }

    bool significativeUpdate = processingState.scheduleChanged || processingState.statusChanged;

    if (significativeUpdate) {
      _logger.trace('[DecisionService] ($videoId) Potential Update Event detected (Schedule/Status Changed).');
      bool onlyCertaintyChangedWithDelay =
          processingState.becameCertain &&
          !processingState.statusChanged &&
          !processingState.mentionsChanged &&
          !processingState.scheduleChanged &&
          delayNewMedia;

      _logger.trace(
        "[$videoId] Update Check: significativeUpdate=$significativeUpdate, onlyCertaintyChangedWithDelay=$onlyCertaintyChangedWithDelay",
      );

      if (!onlyCertaintyChangedWithDelay) {
        if (recentlyDismissed) {
          logger.info('[DecisionService] ($videoId) SUPPRESSING Update notification (Recently Dismissed).');
        } else {
          logger.info('[DecisionService] ($videoId) Dispatching Update notification.');
          actions.add(NotificationAction.dispatch(instruction: _createNotificationInstruction(fetchedVideo, NotificationEventType.update)));
          actions.add(NotificationAction.updateCache(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));
        }
      } else {
        logger.info('[DecisionService] ($videoId) SUPPRESSING Update notification (Only certainty changed & Delay ON).');
      }
    }
    _logger.trace("[$videoId] _determineUpdateEventActions END");
  }

  Future<void> _determineMentionEventActions(
    VideoFull fetchedVideo,
    CachedVideo? cachedVideo,
    List<ChannelSubscriptionSetting> allSettings,
    _ProcessingState processingState,
    List<NotificationAction> actions,
    ILoggingService logger,
    bool recentlyDismissed,
  ) async {
    final videoId = fetchedVideo.id;
    _logger.trace("[$videoId] _determineMentionEventActions START");
    if (!processingState.mentionsChanged) {
      _logger.trace("[$videoId] _determineMentionEventActions END (mentions did not change)");
      return;
    }

    _logger.trace('[DecisionService] ($videoId) Mention Event detected (Mention list changed).');

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
      final mentionTargetSettings = settingsMap[mentionedId];
      if (mentionTargetSettings != null && mentionTargetSettings.notifyMentions) {
        if (recentlyDismissed) {
          logger.info('[DecisionService] ($videoId) SUPPRESSING Mention notification for target $mentionedId (Video Recently Dismissed).');
        } else {
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
          actions.add(NotificationAction.updateCache(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));
        }
      } else {
        logger.debug('[DecisionService] ($videoId) User DOES NOT want mentions for newly mentioned channel $mentionedId. Skipping dispatch.');
      }
    }
    _logger.trace("[$videoId] _determineMentionEventActions END");
  }

  NotificationInstruction _createNotificationInstruction(
    VideoFull video,
    NotificationEventType type, {
    String? mentionTargetId,
    String? mentionTargetName,
  }) {
    String? thumbnailUrl;
    String? sourceLink;

    if (video.type == 'placeholder' && video.thumbnail != null && video.thumbnail!.isNotEmpty) {
      thumbnailUrl = video.thumbnail;
      if (video.link != null && video.link!.isNotEmpty) {
        sourceLink = video.link;
      }
    } else {
      thumbnailUrl = 'https://i.ytimg.com/vi/${video.id}/mqdefault.jpg';
    }

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

    if (!newValue) {
      if (settingKey == 'notifyLive') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyLive. Fetching Live/Reminder notifications to cancel...");
        final List<CachedVideo> scheduledVids = (await _cacheService.getScheduledVideos()).where((v) => v.channelId == channelId).toList();

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
          if (video.isPendingNewMediaNotification) {
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false)),
              ),
            );
            _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to disabled members-only.");
          }
        }
      } else if (settingKey == 'notifyClips') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyClips. Fetching clip videos to cancel notifications/clear pending...");
        final List<CachedVideo> clipVids = await _cacheService.getClipVideosByChannel(channelId);
        for (final video in clipVids) {
          if (video.isPendingNewMediaNotification) {
            actions.add(
              NotificationAction.updateCache(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false)),
              ),
            );
            _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to disabled clips.");
          }
          if (video.scheduledLiveNotificationId != null) {
            actions.add(
              NotificationAction.cancel(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
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
          }
        }
      } else if (settingKey == 'notifyNewMedia') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyNewMedia. Checking for pending videos to clear flag...");
        final List<CachedVideo> potentiallyPending =
            (await _cacheService.getVideosByStatus('new') + await _cacheService.getVideosByStatus('upcoming'))
                .where((v) => v.channelId == channelId && v.isPendingNewMediaNotification)
                .toList();
        for (final video in potentiallyPending) {
          actions.add(
            NotificationAction.updateCache(
              videoId: video.videoId,
              companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false)),
            ),
          );
          _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to disabled notifyNewMedia.");
        }
      }
    } else {
      bool needsScheduleCheck = false;
      List<CachedVideo> videosToCheck = [];

      final allCurrentSettings = await _settingsService.getChannelSubscriptions();
      final currentPersistedSetting = allCurrentSettings.firstWhereOrNull((s) => s.channelId == channelId);

      if (currentPersistedSetting == null) {
        _logger.error("[DecisionService] ($channelId) CRITICAL: Cannot find persisted settings for channel during $settingKey enable check.");
        return [];
      }
      final effectiveSetting = currentPersistedSetting.copyWith(
        notifyLive: (settingKey == 'notifyLive') ? newValue : currentPersistedSetting.notifyLive,
        notifyMembersOnly: (settingKey == 'notifyMembersOnly') ? newValue : currentPersistedSetting.notifyMembersOnly,
        notifyClips: (settingKey == 'notifyClips') ? newValue : currentPersistedSetting.notifyClips,
      );

      if (settingKey == 'notifyLive' || settingKey == 'notifyMembersOnly' || settingKey == 'notifyClips') {
        _logger.debug("[DecisionService] ($channelId) Enabling $settingKey. Checking for missing schedules...");
        needsScheduleCheck = true;
        videosToCheck = (await _cacheService.getVideosByStatus('upcoming')).where((v) => v.channelId == channelId).toList();
      }

      if (needsScheduleCheck && videosToCheck.isNotEmpty) {
        _logger.debug(
          "[DecisionService] ($channelId) Found ${videosToCheck.length} potentially relevant videos for immediate scheduling check after enabling $settingKey.",
        );
        final reminderLeadTime = await _settingsService.getReminderLeadTime();

        for (final video in videosToCheck) {
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

          final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
          if (scheduledTime == null || scheduledTime.isBefore(DateTime.now())) {
            _logger.trace("[DecisionService] ($channelId) Skipping ${video.videoId} in enable check: invalid/past schedule time.");
            continue;
          }

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
        }
      } else if (needsScheduleCheck) {
        _logger.debug("[DecisionService] ($channelId) No relevant videos found in cache for immediate scheduling check after enabling $settingKey.");
      } else {
        _logger.debug("[DecisionService] ($channelId) Enabled $settingKey. No immediate schedule check actions generated.");
      }
    }

    _logger.info("[DecisionService] ($channelId/$settingKey) Determined ${actions.length} actions for setting change.");
    return actions;
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

    final List<CachedVideo> scheduledVids = (await _cacheService.getScheduledVideos()).where((v) => v.channelId == channelId).toList();

    for (final video in scheduledVids) {
      if (video.scheduledLiveNotificationId != null) {
        actions.add(
          NotificationAction.cancel(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
        );
        actions.add(
          NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))),
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
    final List<CachedVideo> potentialPending =
        (await _cacheService.getVideosByStatus('new') + await _cacheService.getVideosByStatus('upcoming'))
            .where((v) => v.channelId == channelId && v.isPendingNewMediaNotification)
            .toList();
    for (final video in potentialPending) {
      actions.add(
        NotificationAction.updateCache(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))),
      );
      _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to channel removal.");
    }

    _logger.info("[DecisionService] ($channelId) Determined ${actions.length} cancellation/cleanup actions for channel removal.");
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

    final List<CachedVideo> allUpcomingVideos =
        (await _cacheService.getVideosByStatus('upcoming')).where((v) => activeChannels.any((ch) => ch.channelId == v.channelId)).toList();

    _logger.debug("[DecisionService] Found ${allUpcomingVideos.length} upcoming videos for channels with notifyLive enabled.");

    for (final video in allUpcomingVideos) {
      final channelSetting = activeChannels.firstWhereOrNull((ch) => ch.channelId == video.channelId);
      if (channelSetting == null) continue;

      if (video.topicId == 'membersonly' && !channelSetting.notifyMembersOnly) continue;
      if (video.videoType == 'clip' && !channelSetting.notifyClips) continue;

      _logger.trace("[DecisionService] (${video.videoId}) Processing for reminder lead time change.");

      if (video.scheduledReminderNotificationId != null) {
        _logger.debug(
          "[DecisionService] (${video.videoId}) Cancelling existing reminder ID ${video.scheduledReminderNotificationId} due to lead time change.",
        );
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

      final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
      if (newLeadTime > Duration.zero && scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        final calculatedReminderTime = scheduledTime.subtract(newLeadTime);
        if (calculatedReminderTime.isAfter(DateTime.now())) {
          _logger.debug(
            "[DecisionService] (${video.videoId}) Scheduling new reminder for $calculatedReminderTime with lead time ${newLeadTime.inMinutes} min.",
          );
          allActions.add(
            NotificationAction.schedule(
              instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.reminder),
              scheduleTime: calculatedReminderTime,
              videoId: video.videoId,
            ),
          );
          allActions.add(
            NotificationAction.updateCache(
              videoId: video.videoId,
              companion: CachedVideosCompanion(
                scheduledReminderNotificationId: const Value(-1),
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

extension on CachedVideo {
  VideoFull toVideoFull() {
    DateTime? tryParseDateTime(String? iso) => iso == null ? null : DateTime.tryParse(iso);
    DateTime parseDateTimeReq(String iso) => DateTime.parse(iso);

    return VideoFull(
      id: videoId,
      title: videoTitle,
      type: videoType ?? 'unknown',
      topicId: topicId,
      publishedAt: null,
      availableAt: parseDateTimeReq(availableAt),
      duration: 0,
      status: status,
      startScheduled: tryParseDateTime(startScheduled),
      startActual: tryParseDateTime(startActual),
      endActual: null,
      liveViewers: null,
      description: null,
      songcount: null,
      channel: ChannelMin(id: channelId, name: channelName, photo: channelAvatarUrl, type: 'vtuber'),
      certainty: certainty,
      thumbnail: null,
      link: null,
      mentions: mentionedChannelIds.map((id) => ChannelMinWithOrg(id: id, name: 'Unknown Channel')).toList(),
    );
  }
}
