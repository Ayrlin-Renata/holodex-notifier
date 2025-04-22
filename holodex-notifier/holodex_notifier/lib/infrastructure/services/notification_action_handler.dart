// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\infrastructure\services\notification_action_handler.dart
import 'package:drift/drift.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

class NotificationActionHandler implements INotificationActionHandler {
  final INotificationService _notificationService;
  final ICacheService _cacheService;
  final ILoggingService _logger;

  NotificationActionHandler(this._notificationService, this._cacheService, this._logger);

  @override
  Future<void> executeActions(List<NotificationAction> actions) async {
    if (actions.isEmpty) {
      _logger.debug("ActionHandler: No actions to execute.");
      return;
    }
    _logger.info("ActionHandler: Executing ${actions.length} actions...");

    Map<String, ({int? liveId, int? reminderId})> scheduledIdsMap = {};
    List<UntrackAndCleanAction> untrackActions = actions.whereType<UntrackAndCleanAction>().toList();

    // --- Step 1: Handle Untracking ---
    for (final action in untrackActions) {
      await _executeSingleAction(action);
    }

    // --- Step 2: Handle Scheduling ---
    for (final action in actions.whereType<ScheduleNotificationAction>()) {
      if (untrackActions.any((ua) => ua.videoId == action.videoId)) continue;
      int? returnedId = await _executeSingleAction(action);
      if (returnedId != null) {
        // Map IDs... (same logic)
        final videoId = action.videoId;
        var currentIds = scheduledIdsMap.putIfAbsent(videoId, () => (liveId: null, reminderId: null));
        if (action.instruction.eventType == NotificationEventType.live) {
          scheduledIdsMap[videoId] = currentIds.copyWith(liveId: returnedId);
        } else if (action.instruction.eventType == NotificationEventType.reminder) {
          scheduledIdsMap[videoId] = currentIds.copyWith(reminderId: returnedId);
        }
      }
    }

    // --- Step 3: Handle OS Cancellations ---
    for (final action in actions.whereType<CancelNotificationAction>()) {
      if (untrackActions.any((ua) => ua.videoId == action.videoId)) continue;
      await _executeSingleAction(action);
    }

    Map<String, CachedVideosCompanion> specifiedUpdates = {};
    for (final action in actions.whereType<UpdateCacheAction>()) {
       if (untrackActions.any((ua) => ua.videoId == action.videoId)) continue;
       final videoId = action.videoId;
        final currentCompanion = specifiedUpdates.putIfAbsent(videoId, () => CachedVideosCompanion(videoId: Value(videoId)));
        // Merge fields (copyWith logic remains the same)
       specifiedUpdates[videoId] = currentCompanion.copyWith( /* ... copy ALL present fields from action.companion ... */
           channelId: action.companion.channelId.present ? action.companion.channelId : currentCompanion.channelId,
            topicId: action.companion.topicId.present ? action.companion.topicId : currentCompanion.topicId,
            status: action.companion.status.present ? action.companion.status : currentCompanion.status,
        startScheduled: action.companion.startScheduled.present ? action.companion.startScheduled : currentCompanion.startScheduled,
        startActual: action.companion.startActual.present ? action.companion.startActual : currentCompanion.startActual,
        availableAt: action.companion.availableAt.present ? action.companion.availableAt : currentCompanion.availableAt,
        videoType: action.companion.videoType.present ? action.companion.videoType : currentCompanion.videoType,
        thumbnailUrl: action.companion.thumbnailUrl.present ? action.companion.thumbnailUrl : currentCompanion.thumbnailUrl,
        certainty: action.companion.certainty.present ? action.companion.certainty : currentCompanion.certainty,
        mentionedChannelIds:
            action.companion.mentionedChannelIds.present ? action.companion.mentionedChannelIds : currentCompanion.mentionedChannelIds,
        videoTitle: action.companion.videoTitle.present ? action.companion.videoTitle : currentCompanion.videoTitle,
        channelName: action.companion.channelName.present ? action.companion.channelName : currentCompanion.channelName,
        channelAvatarUrl: action.companion.channelAvatarUrl.present ? action.companion.channelAvatarUrl : currentCompanion.channelAvatarUrl,
        isPendingNewMediaNotification:
            action.companion.isPendingNewMediaNotification.present
                ? action.companion.isPendingNewMediaNotification
                : currentCompanion.isPendingNewMediaNotification,
        lastSeenTimestamp: action.companion.lastSeenTimestamp.present ? action.companion.lastSeenTimestamp : currentCompanion.lastSeenTimestamp,
        scheduledLiveNotificationId:
            action.companion.scheduledLiveNotificationId.present
                ? action.companion.scheduledLiveNotificationId
                : currentCompanion.scheduledLiveNotificationId,
        lastLiveNotificationSentTime:
            action.companion.lastLiveNotificationSentTime.present
                ? action.companion.lastLiveNotificationSentTime
                : currentCompanion.lastLiveNotificationSentTime,
        scheduledReminderNotificationId:
            action.companion.scheduledReminderNotificationId.present
                ? action.companion.scheduledReminderNotificationId
                : currentCompanion.scheduledReminderNotificationId,
        scheduledReminderTime:
            action.companion.scheduledReminderTime.present ? action.companion.scheduledReminderTime : currentCompanion.scheduledReminderTime,
        userDismissedAt: action.companion.userDismissedAt.present ? action.companion.userDismissedAt : currentCompanion.userDismissedAt,
        sentMentionTargetIds:
            action.companion.sentMentionTargetIds.present ? action.companion.sentMentionTargetIds : currentCompanion.sentMentionTargetIds,
      );
    }

    // --- Step 5: Apply Database Updates ---
    // Iterate through all videos affected by *any* cache update or *newly* scheduled notification.
    Set<String> videosToUpdate = {...specifiedUpdates.keys, ...scheduledIdsMap.keys};

    if (videosToUpdate.isNotEmpty) {
      _logger.debug("ActionHandler: Applying final DB updates for ${videosToUpdate.length} videos...");
      for (final videoId in videosToUpdate) {
          // Skip if untracked during this cycle
          if (untrackActions.any((ua) => ua.videoId == videoId)) continue;

          // 1. Get the potentially merged companion from UpdateCacheActions
          var mergedCompanion = specifiedUpdates[videoId] ?? CachedVideosCompanion(videoId: Value(videoId));

          // 2. Inject actual scheduled IDs into the companion
          if (scheduledIdsMap.containsKey(videoId)) {
              final scheduledIds = scheduledIdsMap[videoId]!;
              if (scheduledIds.liveId != null && mergedCompanion.scheduledLiveNotificationId.present && mergedCompanion.scheduledLiveNotificationId.value == -1) {
                  mergedCompanion = mergedCompanion.copyWith(scheduledLiveNotificationId: Value(scheduledIds.liveId));
              }
              if (scheduledIds.reminderId != null && mergedCompanion.scheduledReminderNotificationId.present && mergedCompanion.scheduledReminderNotificationId.value == -1) {
                 mergedCompanion = mergedCompanion.copyWith(scheduledReminderNotificationId: Value(scheduledIds.reminderId));
              }
          }

         // 3. Replace placeholders if no actual ID was scheduled/injected
          if (mergedCompanion.scheduledLiveNotificationId.present && mergedCompanion.scheduledLiveNotificationId.value == -1) {
              mergedCompanion = mergedCompanion.copyWith(scheduledLiveNotificationId: const Value(null));
          }
         if (mergedCompanion.scheduledReminderNotificationId.present && mergedCompanion.scheduledReminderNotificationId.value == -1) {
              mergedCompanion = mergedCompanion.copyWith(scheduledReminderNotificationId: const Value(null));
           }

          // 4. ALWAYS perform an UPSERT using the final merged companion.
          //    This ensures all required fields are present when writing.
         //    If the companion only contains ID updates from settings changes,
         //    the upsert will effectively act like an update for those fields.
         try {
             _logger.debug("ActionHandler: Executing cache UPSERT for $videoId: ${mergedCompanion.toColumns(true)}");
             await _cacheService.upsertVideo(mergedCompanion); // Requires videoId to be present
              _logger.debug("ActionHandler: Cache upsert operation finished for video $videoId.");
         } catch (e, s) {
             _logger.error("ActionHandler: Failed to execute cache upsert for video $videoId", e, s);
             if (e is InvalidDataException) {
                 _logger.error("ActionHandler: The companion data was invalid for upsert: ${mergedCompanion.toColumns(true)}");
             }
         }
       } // End for loop
       _logger.info("ActionHandler: Finished applying final merged cache updates.");
    } // End if (mergedCacheUpdates.isNotEmpty)


    // --- Step 6: Dispatch Notifications (Last Step) ---
    for (final action in actions.whereType<DispatchNotificationAction>()) {
      if (untrackActions.any((ua) => ua.videoId == action.instruction.videoId)) continue;
      await _executeSingleAction(action);
    }

    _logger.info("ActionHandler: Finished executing all actions.");

  } // End executeActions

  Future<int?> _executeSingleAction(NotificationAction action) async {
    int? newNotificationId;
    try {
      switch (action) {
        case ScheduleNotificationAction(:final instruction, :final scheduleTime, :final videoId):
          _logger.debug("ActionHandler: Scheduling notification for $videoId at $scheduleTime.");
          newNotificationId = await _notificationService.scheduleNotification(instruction: instruction, scheduledTime: scheduleTime);
          if (newNotificationId == null) {
            _logger.warning("ActionHandler: Scheduling returned null ID for $videoId.");
          }
          break;

        case CancelNotificationAction(:final notificationId, :final videoId, :final type):
          _logger.debug("ActionHandler: Cancelling notification ID $notificationId (Type: ${type?.name ?? 'Unknown'}) for video $videoId.");
          await _notificationService.cancelNotification(notificationId);
          break;

        case DispatchNotificationAction(:final instruction):
          _logger.debug("ActionHandler: Dispatching notification for ${instruction.videoId} (Type: ${instruction.eventType}).");
          await _notificationService.showNotification(instruction);
          break;

         case UpdateCacheAction():
            _logger.trace("ActionHandler [SingleExec]: UpdateCache action handled in batch. No action needed here.");
           break;

         case UntrackAndCleanAction(:final videoId, :final liveNotificationId, :final reminderNotificationId):
              _logger.info("ActionHandler [SingleExec]: Executing UntrackAndClean for video $videoId.");
              // Cancel notifications first
               if (liveNotificationId != null) {
                  try {
                       _logger.debug("ActionHandler ($videoId): Untrack - Cancelling Live ID $liveNotificationId");
                      await _notificationService.cancelNotification(liveNotificationId);
                  } catch (e, s) { _logger.error("ActionHandler ($videoId): Untrack - Failed to cancel live notification $liveNotificationId", e, s); }
               }
              if (reminderNotificationId != null) {
                  try {
                      _logger.debug("ActionHandler ($videoId): Untrack - Cancelling Reminder ID $reminderNotificationId");
                       await _notificationService.cancelNotification(reminderNotificationId);
                  } catch (e, s) { _logger.error("ActionHandler ($videoId): Untrack - Failed to cancel reminder notification $reminderNotificationId", e, s); }
               }
              // THEN delete from cache
              try {
                  _logger.debug("ActionHandler ($videoId): Untrack - Deleting from cache.");
                  await _cacheService.deleteVideo(videoId);
              } catch (e, s) { _logger.error("ActionHandler ($videoId): Untrack - Failed to delete video from cache", e, s); }
              break;
       }
     } catch (e, s) { _logger.error("ActionHandler: Failed to execute action $action", e, s); }
     return newNotificationId;

  } // End _executeSingleAction

} // End class

 // ... extension ...
extension _CopyWithMap on ({int? liveId, int? reminderId}) {
  ({int? liveId, int? reminderId}) copyWith({int? liveId, int? reminderId}) {
    return (liveId: liveId ?? this.liveId, reminderId: reminderId ?? this.reminderId);
  }
}