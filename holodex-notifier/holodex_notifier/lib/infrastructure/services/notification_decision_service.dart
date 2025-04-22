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

// {{Introduce VideoProcessingContext}}
/// Holds all relevant information for deciding actions for a video.
class VideoProcessingContext {
  final VideoFull fetchedVideo;
  final CachedVideo? cachedVideo;
  final ChannelSubscriptionSetting? directChannelSettings;
  final List<ChannelSubscriptionSetting> mentionTargetSettings;
  final bool delayNewMedia;
  final Duration reminderLeadTime;
  final DateTime? userDismissedAt;
  final List<String> sentMentionTargetIds;
  final int? scheduledLiveNotificationId;
  final int? scheduledReminderNotificationId;
  final DateTime? scheduledReminderTime;
  final bool wasPendingNewMedia;
  final DateTime? lastLiveNotificationSentTime;

  // Diff flags (calculated for convenience)
  final bool isNewVideo;
  final bool isCertain;
  final bool wasCertain;
  final bool statusChanged;
  final bool scheduleChanged;
  final bool mentionsChanged;
  final bool becameCertain;
  final bool reminderTimeChanged;

  VideoProcessingContext({
    required this.fetchedVideo,
    required this.cachedVideo,
    required List<ChannelSubscriptionSetting> allChannelSettings,
    required Set<String>? mentionedForChannels, // IDs of channels user is subscribed TO for mentions for this specific video
    required this.delayNewMedia,
    required this.reminderLeadTime,
  })  : directChannelSettings = allChannelSettings.firstWhereOrNull((s) => s.channelId == fetchedVideo.channel.id),
        mentionTargetSettings = allChannelSettings.where((s) => mentionedForChannels?.contains(s.channelId) ?? false).toList(),
        userDismissedAt = cachedVideo?.userDismissedAt != null ? DateTime.fromMillisecondsSinceEpoch(cachedVideo!.userDismissedAt!) : null,
        sentMentionTargetIds = cachedVideo?.sentMentionTargetIds ?? [],
        scheduledLiveNotificationId = cachedVideo?.scheduledLiveNotificationId,
        scheduledReminderNotificationId = cachedVideo?.scheduledReminderNotificationId,
        scheduledReminderTime = cachedVideo?.scheduledReminderTime != null ? DateTime.fromMillisecondsSinceEpoch(cachedVideo!.scheduledReminderTime!) : null,
        wasPendingNewMedia = cachedVideo?.isPendingNewMediaNotification ?? false,
        lastLiveNotificationSentTime =
            cachedVideo?.lastLiveNotificationSentTime != null
              ? DateTime.fromMillisecondsSinceEpoch(cachedVideo!.lastLiveNotificationSentTime!)
              : null,
        // Diff logic from old _ProcessingState
        isNewVideo = cachedVideo == null,
        isCertain = (fetchedVideo.certainty == 'certain' || fetchedVideo.certainty == null || fetchedVideo.type != 'placeholder'),
        wasCertain = cachedVideo != null &&
            (cachedVideo.certainty == 'certain' || cachedVideo.certainty == null || cachedVideo.videoType != 'placeholder'),
        statusChanged = cachedVideo != null && cachedVideo.status != fetchedVideo.status,
        scheduleChanged = cachedVideo != null && cachedVideo.startScheduled != fetchedVideo.startScheduled?.toIso8601String(),
        mentionsChanged = cachedVideo != null &&
            !const ListEquality().equals(
              cachedVideo.mentionedChannelIds,
              fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? [],
            ),
        becameCertain = !(cachedVideo != null &&
                (cachedVideo.certainty == 'certain' || cachedVideo.certainty == null || cachedVideo.videoType != 'placeholder')) &&
            (fetchedVideo.certainty == 'certain' || fetchedVideo.certainty == null || fetchedVideo.type != 'placeholder'),
        reminderTimeChanged =
            cachedVideo?.scheduledReminderTime != null && cachedVideo!.startScheduled != fetchedVideo.startScheduled?.toIso8601String();


  // Helper to check if user is subscribed to mentions for at least one channel mentioned in this video
  bool get hasMentionSubscription => mentionTargetSettings.any((s) => s.notifyMentions);

  // Helper to get settings for a specific mention target
  ChannelSubscriptionSetting? getSettingsForMentionTarget(String channelId) {
      return mentionTargetSettings.firstWhereOrNull((s) => s.channelId == channelId);
  }

    // Helper to determine if user is subscribed to direct notifications (respecting type/topic filters)
  bool get wantsDirectNotifications {
    if (directChannelSettings == null) return false;
    if (fetchedVideo.topicId == 'membersonly' && !directChannelSettings!.notifyMembersOnly) return false;
    if (fetchedVideo.type == 'clip' && !directChannelSettings!.notifyClips) return false;

    // Return true if subscribed to *any* relevant notification type for this channel
    return directChannelSettings!.notifyLive ||
           directChannelSettings!.notifyNewMedia ||
           directChannelSettings!.notifyUpdates;
  }

   // Helper to determine if user is subscribed to mention notifications (respecting type/topic filters) for a specific mentioned channel
  bool wantsMentionNotificationsFor(String targetChannelId) {
    final setting = getSettingsForMentionTarget(targetChannelId);
    if (setting == null || !setting.notifyMentions) return false;
    if (fetchedVideo.topicId == 'membersonly' && !setting.notifyMembersOnly) return false;
    if (fetchedVideo.type == 'clip' && !setting.notifyClips) return false;
    return true;
  }

  bool get isDismissed => userDismissedAt != null;

  // Helper to determine if user wants ANY live notification (direct or via mention target)
  bool get wantsAnyLiveNotification {
     // Check direct subscription first
     if (directChannelSettings != null && directChannelSettings!.notifyLive) {
       // Apply direct channel filters
       if (fetchedVideo.topicId == 'membersonly' && !directChannelSettings!.notifyMembersOnly) return false;
       if (fetchedVideo.type == 'clip' && !directChannelSettings!.notifyClips) return false;
       return true; // Wants direct live & passes filters
     }

     // Check if any mention target subscription wants live notifications
     return mentionTargetSettings.any((setting) {
          bool wantsMentionLive = setting.notifyLive && setting.notifyMentions; // Must want both mentions AND live for this target
          if (!wantsMentionLive) return false;
          // Apply mention target filters
         if (fetchedVideo.topicId == 'membersonly' && !setting.notifyMembersOnly) return false;
         if (fetchedVideo.type == 'clip' && !setting.notifyClips) return false;
          return true; // Wants mention-live & passes filters
       });
   }
}

// {{Remove _ProcessingState definition}}
// class _ProcessingState { ... }

class NotificationDecisionService implements INotificationDecisionService {
  final ICacheService _cacheService;
  final ISettingsService _settingsService;
  final ILoggingService _logger;
  static const Duration _videoMaxAge = Duration(hours: 76); // Step 3d

  NotificationDecisionService(this._cacheService, this._settingsService, this._logger);

  @override
  Future<List<NotificationAction>> determineActionsForVideoUpdate({
    required VideoFull fetchedVideo,
    required CachedVideo? cachedVideo,
    required List<ChannelSubscriptionSetting> allChannelSettings,
    required Set<String>? mentionedForChannels, // IDs of channels user is subscribed TO for mentions for this specific video
  }) async {
    final String videoId = fetchedVideo.id;
    final List<NotificationAction> actions = [];
    final DateTime currentSystemTime = DateTime.now();
    _logger.debug("[DecisionService] ($videoId) Determining actions...");

    try {
      // Step 2: Build Context
      final bool delayNewMedia = await _settingsService.getDelayNewMedia();
      final Duration reminderLeadTime = await _settingsService.getReminderLeadTime();
      final context = VideoProcessingContext(
        fetchedVideo: fetchedVideo,
        cachedVideo: cachedVideo,
        allChannelSettings: allChannelSettings,
        mentionedForChannels: mentionedForChannels,
        delayNewMedia: delayNewMedia,
        reminderLeadTime: reminderLeadTime,
      );

      // Step 3: Determine Tracking
      if (!_shouldTrackVideo(context, currentSystemTime)) {
        _logger.info("[DecisionService] ($videoId) Video should NOT be tracked. Generating untrack actions.");
        actions.add(UntrackAndCleanAction(
          videoId: videoId,
          liveNotificationId: context.scheduledLiveNotificationId,
          reminderNotificationId: context.scheduledReminderNotificationId,
        ));
        return actions; // Skip further processing
      }

      _logger.debug("[DecisionService] ($videoId) Video is tracked. Proceeding with action determination.");

      // Step 4: Determine Immediate Dispatch Actions
      actions.addAll(_determineDispatchActions(context, currentSystemTime));

      // Step 5: Determine Scheduling Actions
      actions.addAll(_determineScheduleActions(context, currentSystemTime));

      // Add Base Cache Update (always happens if tracked)
      _addBaseCacheUpdateAction(fetchedVideo, cachedVideo, actions, context);

      _logger.info("[DecisionService] ($videoId) Finished determining ${actions.length} actions for tracked video.");
      return actions;

    } catch (e, s) {
      _logger.error("[DecisionService] ($videoId) Error determining actions for video update", e, s);
      return [];
    }
  }

  /// Step 3: Determines if a video should be tracked based on subscriptions and age.
  bool _shouldTrackVideo(VideoProcessingContext context, DateTime now) {
    final videoId = context.fetchedVideo.id;
    final videoChannelId = context.fetchedVideo.channel.id;

    // Rule 3a: Subscribed to direct notifications from the channel?
    bool subscribedDirect = false;
    if (context.directChannelSettings != null) {
        if (context.directChannelSettings!.notifyLive ||
            context.directChannelSettings!.notifyNewMedia ||
            context.directChannelSettings!.notifyUpdates ||
            context.directChannelSettings!.notifyClips) { // Added clips here as it implies tracking interest
             // Check specific filters
            if (context.fetchedVideo.topicId == 'membersonly' && !context.directChannelSettings!.notifyMembersOnly) {
                // Skip direct tracking if members only and not subscribed
            } else if (context.fetchedVideo.type == 'clip' && !context.directChannelSettings!.notifyClips) {
                 // Skip direct tracking if clip and not subscribed
            } else {
                 subscribedDirect = true;
                 _logger.trace("[DecisionService] ($videoId) Track check: Subscribed directly True (Channel: $videoChannelId).");
           }
        }
    }
     if (subscribedDirect && context.fetchedVideo.topicId == 'membersonly' && !context.directChannelSettings!.notifyMembersOnly) {
            _logger.trace("[DecisionService] ($videoId) Track check: Overriding direct subscription due to members-only filter.");
            subscribedDirect = false;
    }

    if (subscribedDirect && context.fetchedVideo.type == 'clip' && !context.directChannelSettings!.notifyClips) {
            _logger.trace("[DecisionService] ($videoId) Track check: Overriding direct subscription due to clip filter.");
             subscribedDirect = false;
    }


    // Rule 3b: Subscribed to mention notifications for any mentioned channel?
    bool subscribedMention = false;
    if (context.mentionTargetSettings.isNotEmpty) {
       subscribedMention = context.mentionTargetSettings.any((setting) {
           bool wantsMention = setting.notifyMentions;
           if (!wantsMention) return false;
           // Check topic/type filters for the *mention subscription*
           if (context.fetchedVideo.topicId == 'membersonly' && !setting.notifyMembersOnly) return false;
           if (context.fetchedVideo.type == 'clip' && !setting.notifyClips) return false;
           return true; // Wants mentions and passes filters
       });
       if (subscribedMention) {
         _logger.trace("[DecisionService] ($videoId) Track check: Subscribed via mentions True (Targets: ${context.mentionTargetSettings.map((s)=>s.channelId).join(',')}).");
       }
    }


    // Rule 3c: Untrack if neither 3a nor 3b is true
    if (!subscribedDirect && !subscribedMention) {
      _logger.info("[DecisionService] ($videoId) Untracking: Not subscribed directly or via mentions.");
      return false;
    }

    // Rule 3d: Untrack if too old (use availableAt as the reference point)
    final videoStartTime = context.fetchedVideo.startScheduled ?? context.fetchedVideo.startActual ?? context.fetchedVideo.availableAt;
    if (now.difference(videoStartTime) > _videoMaxAge) {
       _logger.info("[DecisionService] ($videoId) Untracking: Video start time ($videoStartTime) is older than max age (${_videoMaxAge.inHours} hours).");
       return false;
    }

    _logger.trace("[DecisionService] ($videoId) Track check: Passed all checks. Should track.");
    return true; // If passes all checks
  }

    /// Step 4: Determines immediate notification dispatches.
  List<NotificationAction> _determineDispatchActions(VideoProcessingContext context, DateTime now) {
    final List<NotificationAction> actions = [];
    final videoId = context.fetchedVideo.id;
    _logger.trace("[$videoId] _determineDispatchActions START");

     // Check Direct Channel Notifications only if user wants them based on filters
    if (context.wantsDirectNotifications) {
      _logger.trace("[$videoId] Checking direct dispatch actions...");
      final channelSettings = context.directChannelSettings!; // Safe due to wantsDirectNotifications check


      // 4.b.i: New Media Notification
       // Condition: (Is new OR was 'missing' and now 'new') AND user wants new media
      final bool isPotentialNew = context.isNewVideo || (context.statusChanged && context.cachedVideo?.status == 'missing' && context.fetchedVideo.status == 'new');
      if (isPotentialNew && channelSettings.notifyNewMedia ) {
          _logger.trace('[$videoId] Potential New Media Event.');
          if (context.delayNewMedia && !context.isCertain) {
              _logger.info('[$videoId] Delaying New Media notification (Uncertainty + Setting ON). Setting pending flag.');
              // {{Fix 1: Use Constructor}}
              actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(true))));
          } else if (context.isDismissed) {
              _logger.info('[$videoId] Suppressing New Media dispatch (Recently Dismissed). Setting pending flag if uncertain.');
              // {{Fix 2 & 3: Use Constructor}}
              if (!context.isCertain) {
                actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(true))));
              } else {
                actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
              }
          } else {
              _logger.info('[$videoId] Dispatching New Media notification.');
              // {{Fix 4 & 5: Use Constructor}}
              actions.add(DispatchNotificationAction(instruction: _createNotificationInstruction(context.fetchedVideo, NotificationEventType.newMedia)));
              actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
          }
      }

      // Pending New Media Trigger (If it was pending and now certain or status non-upcoming/new)
      if (context.wasPendingNewMedia && channelSettings.notifyNewMedia) {
           final bool triggerConditionMet = context.becameCertain || (context.statusChanged && context.fetchedVideo.status != 'upcoming' && context.fetchedVideo.status != 'new');
           if (triggerConditionMet) {
               if (context.isDismissed) {
                   _logger.info('[$videoId] Suppressing Pending New Media dispatch (Recently Dismissed). Clearing pending flag.');
                   // {{Fix 6: Use Constructor}}
                   actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
               } else {
                   _logger.info('[$videoId] Pending New Media condition met. Dispatching.');
                   // {{Fix 7 & 8: Use Constructor}}
                   actions.add(DispatchNotificationAction(instruction: _createNotificationInstruction(context.fetchedVideo, NotificationEventType.newMedia)));
                   actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
                }
            }
       }


      // 4.b.ii: Update Notification (if seen before and schedule changed)
      if (!context.isNewVideo && channelSettings.notifyUpdates && context.scheduleChanged) {
         _logger.trace('[$videoId] Potential Update Event (Schedule Changed).');
          // Avoid sending update if only certainty changed and delay is on (handled by pending logic)
         bool onlyCertaintyChangedWithDelay = context.becameCertain && !context.statusChanged && !context.mentionsChanged && !context.scheduleChanged && context.delayNewMedia;

          if (!onlyCertaintyChangedWithDelay) {
              if (context.isDismissed) {
                  _logger.info('[$videoId] Suppressing Update notification (Recently Dismissed).');
              } else {
                  _logger.info('[$videoId] Dispatching Update notification.');
                  // {{Fix 9: Use Constructor}}
                  actions.add(DispatchNotificationAction(instruction: _createNotificationInstruction(context.fetchedVideo, NotificationEventType.update)));
                 // Reset dismissal on update
                  // {{Fix 10: Use Constructor}}
                  actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));
              }
          } else {
             _logger.info('[$videoId] SUPPRESSING Update notification (Only certainty changed & Delay ON).');
          }
      }

       // Immediate Live Notification (if status changes to 'live')
       if (context.statusChanged && context.fetchedVideo.status == 'live' && channelSettings.notifyLive) {
          _logger.trace('[$videoId] Live Event detected (Became Live).');
          const Duration debounceDuration = Duration(minutes: 2);
          DateTime? lastSentTime = context.lastLiveNotificationSentTime;
          bool shouldSend = true;
          if (lastSentTime != null) {
              final timeSinceLastSent = now.difference(lastSentTime);
              if (timeSinceLastSent < debounceDuration) {
                 _logger.info('[$videoId] SUPPRESSING Live notification (Sent ${timeSinceLastSent.inSeconds}s ago).');
                  shouldSend = false;
              }
           }

           if (shouldSend) {
               if (context.isDismissed) {
                   _logger.info('[$videoId] SUPPRESSING Live notification (Recently Dismissed).');
               } else {
                   _logger.info('[$videoId] Dispatching immediate Live notification.');
                   // {{Fix 11: Use Constructor}}
                   actions.add(DispatchNotificationAction(instruction: _createNotificationInstruction(context.fetchedVideo, NotificationEventType.live)));
                  // Update last sent time in cache
                   // {{Fix 12: Use Constructor}}
                   actions.add(UpdateCacheAction(videoId: videoId, companion: CachedVideosCompanion(lastLiveNotificationSentTime: Value(now.millisecondsSinceEpoch))));
                  // Reset dismissal on live dispatch
                   // {{Fix 13: Use Constructor}}
                   actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));
                }
            }
        }

    } else {
       _logger.trace("[$videoId] Skipping direct dispatch actions (user settings).");
    }


    // 4.c: Mention Notification
    if (context.mentionTargetSettings.isNotEmpty) {
       _logger.trace("[$videoId] Checking mention dispatch actions...");
       final List<String> newlySentMentions = [];

       for (final mentionedChannelId in context.mentionTargetSettings.map((s) => s.channelId)) {
           if (context.wantsMentionNotificationsFor(mentionedChannelId)) {
               if (!context.sentMentionTargetIds.contains(mentionedChannelId)) {
                   if (context.isDismissed) {
                       _logger.info('[$videoId] SUPPRESSING Mention notification for target $mentionedChannelId (Recently Dismissed).');
                   } else {
                      final mentionDetails = context.fetchedVideo.mentions?.firstWhereOrNull((m) => m.id == mentionedChannelId);
                       final targetChannelName = mentionDetails?.name ?? context.getSettingsForMentionTarget(mentionedChannelId)!.name;
                      _logger.info('[$videoId] Dispatching Mention notification for target $mentionedChannelId ($targetChannelName).');

                       // {{Fix 14: Use Constructor}}
                       actions.add(DispatchNotificationAction(
                           instruction: _createNotificationInstruction(
                           context.fetchedVideo,
                           NotificationEventType.mention,
                           mentionTargetId: mentionedChannelId,
                           mentionTargetName: targetChannelName,
                           // mentionedChannelNames list isn't strictly needed if using targetName, pass empty or null
                           mentionedChannelNames: null,
                           ),
                       ));
                       newlySentMentions.add(mentionedChannelId);
                      // Reset dismissal on mention dispatch
                       // {{Fix 15: Use Constructor}}
                       actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));
                   }
               } else {
                   _logger.trace('[$videoId] Skipping mention dispatch for $mentionedChannelId (already sent).');
               }
           } else {
              _logger.trace('[$videoId] Skipping mention dispatch for $mentionedChannelId (user settings/filters).');
           }
       }
       if (newlySentMentions.isNotEmpty) {
           final updatedList = [...context.sentMentionTargetIds, ...newlySentMentions];
           // {{Fix 16: Use Constructor}}
           actions.add(UpdateCacheAction(videoId: videoId, companion: CachedVideosCompanion(sentMentionTargetIds: Value(updatedList))));
       }
    }

    _logger.trace("[$videoId] _determineDispatchActions END - Actions: ${actions.length}");
    return actions;
  }

  /// Step 5: Determines notification scheduling/cancellation actions.
  List<NotificationAction> _determineScheduleActions(VideoProcessingContext context, DateTime now) {
    // {{ Fix 1: Use wantsAnyLiveNotification }}
    final List<NotificationAction> actions = [];
    final videoId = context.fetchedVideo.id;
    _logger.trace("[$videoId] _determineScheduleActions START");

    final scheduledTime = context.fetchedVideo.startScheduled;

    // Conditions for any scheduling: Tracked, has future start time, not dismissed
    final bool canSchedule = scheduledTime != null && scheduledTime.isAfter(now) && !context.isDismissed;

    if (!canSchedule) {
       _logger.trace("[$videoId] Cannot schedule (time in past, not upcoming, or dismissed). Cancelling existing.");
       if (context.scheduledLiveNotificationId != null) {
        // {{Fix 17 & 18: Use Constructor}}
        actions.add(CancelNotificationAction(notificationId: context.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live));
        actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
      }
      if (context.scheduledReminderNotificationId != null) {
        // {{Fix 19 & 20: Use Constructor}}
        actions.add(CancelNotificationAction(notificationId: context.scheduledReminderNotificationId!, videoId: videoId, type: NotificationEventType.reminder));
        actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null))));
      }
      return actions;
    }

   // Live Notification Scheduling (5a)
   final bool wantsLive = context.wantsAnyLiveNotification; // Use the corrected helper
   final bool shouldScheduleLive = wantsLive && context.fetchedVideo.status == 'upcoming'; // Must be 'upcoming' to schedule live start
   final bool isLiveScheduled = context.scheduledLiveNotificationId != null;
   final bool needsLiveReschedule = context.scheduleChanged || context.becameCertain;

    _logger.trace("[$videoId] Live Schedule Check: wantsLive=$wantsLive, shouldScheduleLive=$shouldScheduleLive, isLiveScheduled=$isLiveScheduled, needsLiveReschedule=$needsLiveReschedule");

    if (shouldScheduleLive) {
        if (!isLiveScheduled || needsLiveReschedule) {
           _logger.info("[$videoId] Scheduling/Rescheduling LIVE notification for $scheduledTime.");
            if (isLiveScheduled) {
              // {{Fix 21 & 22: Use Constructor}}
              actions.add(CancelNotificationAction(notificationId: context.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live));
              actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
            }
            final instruction = _createNotificationInstruction(context.fetchedVideo, NotificationEventType.live, mentionedChannelNames: []);
            // {{Fix 23: Use Constructor}}
            actions.add(ScheduleNotificationAction(instruction: instruction, scheduleTime: scheduledTime!, videoId: videoId)); // Use ! as canSchedule checked non-null
            // {{Fix 24: Use Constructor}}
            actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(-1))));
        } else {
            _logger.trace("[$videoId] Live notification already scheduled correctly.");
        }
    } else if (isLiveScheduled) {
       _logger.info("[$videoId] Cancelling existing LIVE notification.");
        // {{Fix 25 & 26: Use Constructor}}
        actions.add(CancelNotificationAction(notificationId: context.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live));
        actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
    }

    // Reminder Notification Scheduling (5b)
    final bool wantsReminders = wantsLive && context.reminderLeadTime > Duration.zero; // Reminder depends on wanting Live notif
    final bool shouldScheduleReminder = wantsReminders && context.fetchedVideo.status == 'upcoming';
    final bool isReminderScheduled = context.scheduledReminderNotificationId != null;
    final bool needsReminderReschedule = context.scheduleChanged || context.becameCertain || context.reminderTimeChanged;
    final DateTime targetReminderTime = scheduledTime!.subtract(context.reminderLeadTime);

    _logger.trace("[$videoId] Reminder Schedule Check: wantsReminders=$wantsReminders, shouldScheduleReminder=$shouldScheduleReminder, isReminderScheduled=$isReminderScheduled, needsReminderReschedule=$needsReminderReschedule, targetTime=$targetReminderTime");

    if (shouldScheduleReminder && targetReminderTime.isAfter(now)) {
        if (!isReminderScheduled || needsReminderReschedule) {
           _logger.info("[$videoId] Scheduling/Rescheduling REMINDER notification for $targetReminderTime.");
            if (isReminderScheduled) {
              // {{Fix 27 & 28: Use Constructor}}
              actions.add(CancelNotificationAction(notificationId: context.scheduledReminderNotificationId!, videoId: videoId, type: NotificationEventType.reminder));
              actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null))));
            }
            final instruction = _createNotificationInstruction(context.fetchedVideo, NotificationEventType.reminder, mentionedChannelNames: []);
           // {{Fix 29: Use Constructor}}
            actions.add(ScheduleNotificationAction(instruction: instruction, scheduleTime: targetReminderTime, videoId: videoId));
            // {{Fix 30: Use Constructor}}
            actions.add(UpdateCacheAction(
               videoId: videoId,
                companion: CachedVideosCompanion(
                   scheduledReminderNotificationId: const Value(-1),
                   scheduledReminderTime: Value(targetReminderTime.millisecondsSinceEpoch),
               ),
           ));
        } else {
           _logger.trace("[$videoId] Reminder notification already scheduled correctly.");
        }
    } else if (isReminderScheduled) {
        _logger.info("[$videoId] Cancelling existing REMINDER notification (should not be scheduled or time is past).");
        // {{Fix 31 & 32: Use Constructor}}
        actions.add(CancelNotificationAction(notificationId: context.scheduledReminderNotificationId!, videoId: videoId, type: NotificationEventType.reminder));
       actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null))));
    }

     _logger.trace("[$videoId] _determineScheduleActions END - Actions: ${actions.length}");
    return actions;
  }

 void _addBaseCacheUpdateAction(VideoFull fetchedVideo, CachedVideo? cachedVideo, List<NotificationAction> actions, VideoProcessingContext context) {
     final videoId = fetchedVideo.id;
     String? videoThumbnailUrl;
       if (fetchedVideo.type == 'placeholder' && fetchedVideo.thumbnail != null && fetchedVideo.thumbnail!.isNotEmpty) {
           videoThumbnailUrl = fetchedVideo.thumbnail;
       } else {
            videoThumbnailUrl = 'https://i.ytimg.com/vi/${fetchedVideo.id}/mqdefault.jpg';
      }

       final companion = CachedVideosCompanion(
           videoId: Value(videoId),
           channelId: Value(fetchedVideo.channel.id),
           status: Value(fetchedVideo.status),
           startScheduled: Value(fetchedVideo.startScheduled?.toIso8601String()),
           startActual: Value(fetchedVideo.startActual?.toIso8601String()),
           availableAt: Value(fetchedVideo.availableAt.toIso8601String()),
           videoType: Value(fetchedVideo.type),
           thumbnailUrl: Value(videoThumbnailUrl),
           topicId: Value(fetchedVideo.topicId),
           certainty: Value(fetchedVideo.certainty),
           mentionedChannelIds: Value(fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? []),
           videoTitle: Value(fetchedVideo.title),
           channelName: Value(fetchedVideo.channel.name),
           channelAvatarUrl: Value(fetchedVideo.channel.photo),
           lastSeenTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
           // Note: Scheduled IDs, pending status, last sent time, etc., are updated via specific actions added by the logic methods or the handler
       );

       // {{Fix 33: Use Constructor}}
       actions.add(UpdateCacheAction(videoId: videoId, companion: companion));
       _logger.trace("[DecisionService] ($videoId) Added base cache update action.");
 }

  NotificationInstruction _createNotificationInstruction(
    VideoFull video,
    NotificationEventType type, {
    String? mentionTargetId,
    String? mentionTargetName,
    List<String>? mentionedChannelNames, // Pass this down if needed by format template for specific types
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

    // Placeholder for potentially resolving all mentioned channel names if needed by format
    // List<String> resolvedMentionNames = [];
     // if (mentionedChannelNames != null && mentionedChannelNames.isNotEmpty) {
     //   // potentially look up names from settings here if needed, but often not required for notification itself
     //   resolvedMentionNames = mentionedChannelNames;
     // }


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
      mentionedChannelNames: mentionedChannelNames, // Pass resolved names if needed
      videoThumbnailUrl: thumbnailUrl,
      videoSourceLink: sourceLink,
    );
  }

  // --- Settings Change Handlers ---
  // These can largely remain as they are, but ensure they use the consistent
  // _createNotificationInstruction method if they generate schedule actions.
  // They primarily query the cache and generate bulk actions, which is a
  // different pattern than the per-video update logic.

    // Helper to get mention names - Keep this if used by settings change logic
  Future<List<String>> _getMentionedChannelNames(List<ChannelMinWithOrg>? mentions, List<ChannelSubscriptionSetting> allSettings) async {
     if (mentions == null || mentions.isEmpty) {
       return [];
     }
     final Map<String, String> settingsNameMap = {for (var s in allSettings) s.channelId: s.name};
     final List<String> names = [];
     for (final mention in mentions) {
       names.add(settingsNameMap[mention.id] ?? mention.name);
     }
     return names;
   }

  // --------- Implement/Fix Interface Methods ---------
  @override
  Future<List<NotificationAction>> determineActionsForChannelSettingChange({
    required String channelId,
    required String settingKey,
    required bool oldValue,
    required bool newValue,
  }) async {
    // {{Fix 34: Use Correct Constructors throughout this method}}
    _logger.info("[DecisionService] ($channelId) Determining actions for setting change: $settingKey ($oldValue -> $newValue)");
    final List<NotificationAction> actions = [];
    if (newValue == oldValue) return actions;

    if (!newValue) {
        // --- Logic for DISABLING settings ---
        if (settingKey == 'notifyLive') {
            _logger.debug("[DecisionService] ($channelId) Disabling notifyLive. Fetching Live/Reminder notifications to cancel...");
            final List<CachedVideo> scheduledVids = (await _cacheService.getScheduledVideos()).where((v) => v.channelId == channelId).toList();
            for (final video in scheduledVids) {
                if (video.scheduledLiveNotificationId != null) {
                    actions.add(CancelNotificationAction(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live));
                    actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
                }
                if (video.scheduledReminderNotificationId != null) {
                    actions.add(CancelNotificationAction(notificationId: video.scheduledReminderNotificationId!, videoId: video.videoId, type: NotificationEventType.reminder));
                    actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null))));
                }
            }
        } else if (settingKey == 'notifyMembersOnly') {
            _logger.debug("[DecisionService] ($channelId) Disabling notifyMembersOnly. Fetching members-only videos to cancel/clear pending...");
            final List<CachedVideo> membersVids = await _cacheService.getMembersOnlyVideosByChannel(channelId);
             for (final video in membersVids) {
                 if (video.scheduledLiveNotificationId != null) {
                    actions.add(CancelNotificationAction(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live));
                     actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
                 }
                if (video.scheduledReminderNotificationId != null) {
                     actions.add(CancelNotificationAction(notificationId: video.scheduledReminderNotificationId!, videoId: video.videoId, type: NotificationEventType.reminder));
                     actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null))));
                 }
                if (video.isPendingNewMediaNotification) {
                    actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
                 }
             }
        } else if (settingKey == 'notifyClips') {
            _logger.debug("[DecisionService] ($channelId) Disabling notifyClips. Fetching clip videos to cancel/clear pending...");
            final List<CachedVideo> clipVids = await _cacheService.getClipVideosByChannel(channelId);
            for (final video in clipVids) {
                if (video.isPendingNewMediaNotification) {
                    actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
                }
                 // Also cancel schedules if disabling clips might affect them (if clips can be scheduled)
                if (video.scheduledLiveNotificationId != null) {
                    actions.add(CancelNotificationAction(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live));
                    actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
                 }
                if (video.scheduledReminderNotificationId != null) {
                    actions.add(CancelNotificationAction(notificationId: video.scheduledReminderNotificationId!, videoId: video.videoId, type: NotificationEventType.reminder));
                    actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null))));
                 }
            }
        } else if (settingKey == 'notifyNewMedia') {
             _logger.debug("[DecisionService] ($channelId) Disabling notifyNewMedia. Clearing pending flags...");
             final List<CachedVideo> potentiallyPending = (await _cacheService.getVideosByStatus('new') + await _cacheService.getVideosByStatus('upcoming'))
                .where((v) => v.channelId == channelId && v.isPendingNewMediaNotification)
                .toList();
             for (final video in potentiallyPending) {
                 actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
             }
         }
        // Add other flags if needed (updates, mentions - disabling doesn't usually require cancellation)

    } else {
        // --- Logic for ENABLING settings ---
        bool needsScheduleCheck = false;
        List<CachedVideo> videosToCheck = [];

        final allCurrentSettings = await _settingsService.getChannelSubscriptions();
        final currentPersistedSetting = allCurrentSettings.firstWhereOrNull((s) => s.channelId == channelId);

        if (currentPersistedSetting == null) {
            _logger.error("[DecisionService] ($channelId) CRITICAL: Cannot find persisted settings for channel during $settingKey enable check.");
            return []; // Or handle error appropriately
        }

       // Create an effective setting reflecting the change being processed
       final effectiveSetting = currentPersistedSetting.copyWith(
            notifyLive: (settingKey == 'notifyLive') ? newValue : currentPersistedSetting.notifyLive,
            notifyMembersOnly: (settingKey == 'notifyMembersOnly') ? newValue : currentPersistedSetting.notifyMembersOnly,
           notifyClips: (settingKey == 'notifyClips') ? newValue : currentPersistedSetting.notifyClips,
            // Add other settings if needed
        );

       // Determine if we need to check for schedules (e.g., enabling live, or a filter that reveals scheduled items)
       if (settingKey == 'notifyLive' || settingKey == 'notifyMembersOnly' || settingKey == 'notifyClips') {
            _logger.debug("[DecisionService] ($channelId) Enabling $settingKey. Checking for missing schedules...");
            needsScheduleCheck = true;
            // Get potentially relevant videos (upcoming for this channel)
           videosToCheck = (await _cacheService.getVideosByStatus('upcoming')).where((v) => v.channelId == channelId).toList();
       }
        // Add other conditions for needing a schedule check if necessary (e.g., if notifyNewMedia enabled, maybe check pending flags?)

        if (needsScheduleCheck && videosToCheck.isNotEmpty) {
             _logger.debug("[DecisionService] ($channelId) Found ${videosToCheck.length} videos for schedule check after enabling $settingKey.");
             final reminderLeadTime = await _settingsService.getReminderLeadTime(); // Fetch once

             for (final video in videosToCheck) {
                 // Check if the video should be scheduled based on the *effective* settings
                  if (!effectiveSetting.notifyLive) continue; // Base check
                  if (video.topicId == 'membersonly' && !effectiveSetting.notifyMembersOnly) continue;
                  if (video.videoType == 'clip' && !effectiveSetting.notifyClips) continue;

                 final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
                 if (scheduledTime == null || scheduledTime.isBefore(DateTime.now())) continue;


                  // Check and schedule LIVE if needed
                  if (video.scheduledLiveNotificationId == null) {
                     _logger.debug("[DecisionService] ($channelId) Queuing schedule action for LIVE on ${video.videoId}.");
                     actions.add(ScheduleNotificationAction(
                           instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.live),
                           scheduleTime: scheduledTime,
                           videoId: video.videoId,
                       ));
                      actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(-1))));
                   }

                   // Check and schedule REMINDER if needed
                  if (reminderLeadTime > Duration.zero && video.scheduledReminderNotificationId == null) {
                     final calculatedReminderTime = scheduledTime.subtract(reminderLeadTime);
                       if (calculatedReminderTime.isAfter(DateTime.now())) {
                            _logger.debug("[DecisionService] ($channelId) Queuing schedule action for REMINDER on ${video.videoId}.");
                           actions.add(ScheduleNotificationAction(
                                instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.reminder),
                                scheduleTime: calculatedReminderTime,
                                videoId: video.videoId,
                           ));
                           actions.add(UpdateCacheAction(
                              videoId: video.videoId,
                               companion: CachedVideosCompanion(
                                    scheduledReminderNotificationId: const Value(-1),
                                   scheduledReminderTime: Value(calculatedReminderTime.millisecondsSinceEpoch),
                               ),
                           ));
                       }
                   }
             }
         } else if (needsScheduleCheck) {
             _logger.debug("[DecisionService] ($channelId) No relevant videos found for schedule check after enabling $settingKey.");
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
      // This implementation seems correct - it iterates and calls the single change handler.
     _logger.info("[DecisionService] Determining actions for applying global defaults...");
    final List<NotificationAction> allActions = [];
     final Map<String, ChannelSubscriptionSetting> oldSettingsMap = {for (var s in oldSettings) s.channelId: s};

    for (final newSetting in newSettings) {
       final oldSetting = oldSettingsMap[newSetting.channelId];
       if (oldSetting == null) continue;

       if (oldSetting.notifyLive != newSetting.notifyLive) {
           allActions.addAll(await determineActionsForChannelSettingChange(channelId: newSetting.channelId, settingKey: 'notifyLive', oldValue: oldSetting.notifyLive, newValue: newSetting.notifyLive));
       }
       if (oldSetting.notifyMembersOnly != newSetting.notifyMembersOnly) {
            allActions.addAll(await determineActionsForChannelSettingChange(channelId: newSetting.channelId, settingKey: 'notifyMembersOnly', oldValue: oldSetting.notifyMembersOnly, newValue: newSetting.notifyMembersOnly));
       }
       if (oldSetting.notifyClips != newSetting.notifyClips) {
             allActions.addAll(await determineActionsForChannelSettingChange(channelId: newSetting.channelId, settingKey: 'notifyClips', oldValue: oldSetting.notifyClips, newValue: newSetting.notifyClips));
         }
       if (oldSetting.notifyNewMedia != newSetting.notifyNewMedia) {
             allActions.addAll(await determineActionsForChannelSettingChange(channelId: newSetting.channelId, settingKey: 'notifyNewMedia', oldValue: oldSetting.notifyNewMedia, newValue: newSetting.notifyNewMedia));
         }
       if (oldSetting.notifyUpdates != newSetting.notifyUpdates) {
             allActions.addAll(await determineActionsForChannelSettingChange(channelId: newSetting.channelId, settingKey: 'notifyUpdates', oldValue: oldSetting.notifyUpdates, newValue: newSetting.notifyUpdates));
         }
       if (oldSetting.notifyMentions != newSetting.notifyMentions) {
              allActions.addAll(await determineActionsForChannelSettingChange(channelId: newSetting.channelId, settingKey: 'notifyMentions', oldValue: oldSetting.notifyMentions, newValue: newSetting.notifyMentions));
          }
    }
    _logger.info("[DecisionService] Determined ${allActions.length} actions for global defaults application.");
    return allActions;
  }

  @override
  Future<List<NotificationAction>> determineActionsForChannelRemoval({required String channelId}) async {
    // {{Fix 35: Use Correct Constructors}}
    _logger.info("[DecisionService] ($channelId) Determining actions for channel removal...");
    final List<NotificationAction> actions = [];

    final List<CachedVideo> scheduledVids = (await _cacheService.getScheduledVideos()).where((v) => v.channelId == channelId).toList();

    for (final video in scheduledVids) {
      if (video.scheduledLiveNotificationId != null) {
        actions.add(CancelNotificationAction(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live));
        actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
      }
      if (video.scheduledReminderNotificationId != null) {
        actions.add(CancelNotificationAction(notificationId: video.scheduledReminderNotificationId!, videoId: video.videoId, type: NotificationEventType.reminder));
        actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null))));
      }
    }
    final List<CachedVideo> potentialPending =
        (await _cacheService.getVideosByStatus('new') + await _cacheService.getVideosByStatus('upcoming'))
            .where((v) => v.channelId == channelId && v.isPendingNewMediaNotification)
            .toList();
    for (final video in potentialPending) {
      actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
      _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to channel removal.");
    }


    // Also, remove the video from the cache entirely if it's *only* associated with this removed channel
    // (Assuming a video belongs to only one primary channel)
     try {
           final List<String> videosToRemove = (await _cacheService.getVideosByChannel(channelId)).map((v) => v.videoId).toList();
            _logger.info("[DecisionService] ($channelId) Found ${videosToRemove.length} videos in cache associated with removed channel.");
           for (final videoIdToRemove in videosToRemove) {
                // Check if it's mentioned by *another* subscribed channel first?
                // For simplicity, let's assume removal means removing the video cache entry if its primary channel is removed.
                // A more complex logic could check if it's still relevant via mentions. Let's stick to simpler for now.
                _logger.debug("[DecisionService] ($channelId) Adding cache deletion for video $videoIdToRemove");
                // We could use UpdateCacheAction to set a 'to_be_deleted' status, or modify Untrack action,
                // but simpler might be to just delete here if the action handler supports it, or add a specific DeleteCacheAction.
                // Let's use the existing Untrack action which now handles deletion.
                 final cachedVid = await _cacheService.getVideo(videoIdToRemove); // Fetch to get notification IDs
                 actions.add(UntrackAndCleanAction(
                     videoId: videoIdToRemove,
                     liveNotificationId: cachedVid?.scheduledLiveNotificationId,
                     reminderNotificationId: cachedVid?.scheduledReminderNotificationId,
                 ));
           }
       } catch (e, s) {
          _logger.error("[DecisionService] ($channelId) Error querying/processing videos for removal cleanup.", e, s);
       }



    _logger.info("[DecisionService] ($channelId) Determined ${actions.length} cancellation/cleanup actions for channel removal.");
    return actions;
  }

  @override
  Future<List<NotificationAction>> determineActionsForReminderLeadTimeChange({required Duration oldLeadTime, required Duration newLeadTime}) async {
    // {{Fix 36: Use Correct Constructors}}
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

      // Always cancel existing reminder if present
      if (video.scheduledReminderNotificationId != null) {
        _logger.debug(
          "[DecisionService] (${video.videoId}) Cancelling existing reminder ID ${video.scheduledReminderNotificationId} due to lead time change.",
        );
        allActions.add(CancelNotificationAction(
          notificationId: video.scheduledReminderNotificationId!,
          videoId: video.videoId,
          type: NotificationEventType.reminder,
        ));
        allActions.add(UpdateCacheAction(
          videoId: video.videoId,
           companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
        ));
      }

      // Schedule new reminder if conditions met
      final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
      if (newLeadTime > Duration.zero && scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        final calculatedReminderTime = scheduledTime.subtract(newLeadTime);
        if (calculatedReminderTime.isAfter(DateTime.now())) {
          _logger.debug(
            "[DecisionService] (${video.videoId}) Scheduling new reminder for $calculatedReminderTime with lead time ${newLeadTime.inMinutes} min.",
          );
          allActions.add(ScheduleNotificationAction(
            instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.reminder),
            scheduleTime: calculatedReminderTime,
            videoId: video.videoId,
          ));
          allActions.add(UpdateCacheAction(
            videoId: video.videoId,
            companion: CachedVideosCompanion(
              scheduledReminderNotificationId: const Value(-1),
              scheduledReminderTime: Value(calculatedReminderTime.millisecondsSinceEpoch),
            ),
          ));
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


} // End of class

// {{Fix 37: Remove extra `}` maybe? Or fix the syntax error before this line}}
// It seems the syntax errors were inside the clipped section of determineActionsForChannelSettingChange
// The corrections above using the proper constructors should resolve them. Let's ensure the class ends correctly.


// Extension should be outside the class
extension on CachedVideo {
  VideoFull toVideoFull() {
    DateTime? tryParseDateTime(String? iso) => iso == null ? null : DateTime.tryParse(iso);
    DateTime parseDateTimeReq(String iso) => DateTime.parse(iso); // Consider handling parse failure more gracefully?

    List<ChannelMinWithOrg> mentions = [];
    try {
      mentions = mentionedChannelIds.map((id) => ChannelMinWithOrg(id: id, name: 'Unknown Channel')).toList();
    } catch (e) {
      // Handle potential errors if mentionedChannelIds is not a valid list/iterable
    }


    return VideoFull(
      id: videoId,
      title: videoTitle,
      type: videoType ?? 'unknown',
      topicId: topicId,
      publishedAt: null, // Not stored in cache
      availableAt: parseDateTimeReq(availableAt), // Assumes availableAt is always valid
      duration: 0, // Not stored in cache
      status: status,
      startScheduled: tryParseDateTime(startScheduled),
      startActual: tryParseDateTime(startActual),
      endActual: null, // Not stored in cache
      liveViewers: null, // Not stored in cache
      description: null, // Not stored in cache
      songcount: null, // Not stored in cache
      channel: ChannelMin(id: channelId, name: channelName, photo: channelAvatarUrl, type: 'vtuber'), // Type assumed
      certainty: certainty,
      thumbnail: null, // Not stored in cache, could derive from videoId potentially
      link: null, // Not stored in cache
      mentions: mentions,
    );
  }
}