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

    List<ScheduleNotificationAction> scheduleActions = actions.whereType<ScheduleNotificationAction>().toList();
    List<NotificationAction> nonScheduleActions = actions.where((a) => a is! ScheduleNotificationAction).toList();

    Map<String, ({int? liveId, int? reminderId})> scheduledIdsMap = {};
    for (final action in scheduleActions) {
      int? returnedId = await _executeSingleAction(action);
      if (returnedId != null && action.videoId != null) {
        final videoId = action.videoId!;
        var currentIds = scheduledIdsMap.putIfAbsent(videoId, () => (liveId: null, reminderId: null));
        if (action.instruction.eventType == NotificationEventType.live) {
          scheduledIdsMap[videoId] = currentIds.copyWith(liveId: returnedId);
          _logger.debug("ActionHandler: Scheduled Live for $videoId, got ID: $returnedId");
        } else if (action.instruction.eventType == NotificationEventType.reminder) {
          scheduledIdsMap[videoId] = currentIds.copyWith(reminderId: returnedId);
          _logger.debug("ActionHandler: Scheduled Reminder for $videoId, got ID: $returnedId");
        }
      }
    }

    Map<String, CachedVideosCompanion> mergedCacheUpdates = {};

    for (final action in nonScheduleActions) {
      if (action is UpdateCacheAction) {
        final videoId = action.videoId;
        final currentCompanion = mergedCacheUpdates.putIfAbsent(videoId, () => const CachedVideosCompanion());

        mergedCacheUpdates[videoId] = currentCompanion.copyWith(
          videoId: action.companion.videoId.present ? action.companion.videoId : currentCompanion.videoId,
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
        _logger.trace("ActionHandler: Merged update for $videoId. Result: ${mergedCacheUpdates[videoId]?.toColumns(true)}");
      }
    }

    if (mergedCacheUpdates.isNotEmpty) {
      _logger.debug("ActionHandler: Processing final merged cache updates for ${mergedCacheUpdates.length} videos...");
      for (final entry in mergedCacheUpdates.entries) {
        final videoId = entry.key;
        var companionToUpdate = entry.value;

        if (scheduledIdsMap.containsKey(videoId)) {
          final scheduledIds = scheduledIdsMap[videoId]!;
          if (scheduledIds.liveId != null &&
              companionToUpdate.scheduledLiveNotificationId.present &&
              companionToUpdate.scheduledLiveNotificationId.value == -1) {
            _logger.debug("ActionHandler: Injecting actual SCHEDULED LIVE ID ${scheduledIds.liveId} into cache update for $videoId");
            companionToUpdate = companionToUpdate.copyWith(scheduledLiveNotificationId: Value(scheduledIds.liveId));
          }
          if (scheduledIds.reminderId != null &&
              companionToUpdate.scheduledReminderNotificationId.present &&
              companionToUpdate.scheduledReminderNotificationId.value == -1) {
            _logger.debug("ActionHandler: Injecting actual SCHEDULED REMINDER ID ${scheduledIds.reminderId} into cache update for $videoId");
            companionToUpdate = companionToUpdate.copyWith(scheduledReminderNotificationId: Value(scheduledIds.reminderId));
          }
        }

        if (companionToUpdate.scheduledLiveNotificationId.present && companionToUpdate.scheduledLiveNotificationId.value == -1) {
          _logger.trace("ActionHandler: Replacing placeholder Live ID with null for $videoId");
          companionToUpdate = companionToUpdate.copyWith(scheduledLiveNotificationId: const Value(null));
        }
        if (companionToUpdate.scheduledReminderNotificationId.present && companionToUpdate.scheduledReminderNotificationId.value == -1) {
          _logger.trace("ActionHandler: Replacing placeholder Reminder ID with null for $videoId");
          companionToUpdate = companionToUpdate.copyWith(scheduledReminderNotificationId: const Value(null));
        }

        if (!companionToUpdate.videoId.present) {
          _logger.error(
            "[ActionHandler] CRITICAL: videoId is missing from final companion for upsert! Video ID (key): $videoId. Companion: ${companionToUpdate.toColumns(true)}",
          );

          companionToUpdate = companionToUpdate.copyWith(videoId: Value(videoId));
        }

        try {
          _logger.debug("ActionHandler: Executing final cache upsert for $videoId: ${companionToUpdate.toColumns(true)}");

          await _cacheService.upsertVideo(companionToUpdate);
          _logger.debug("ActionHandler: Cache upsert finished for video $videoId.");
        } catch (e, s) {
          _logger.error("ActionHandler: Failed to execute final cache upsert for video $videoId", e, s);
          if (e is InvalidDataException) {
            _logger.error("ActionHandler: The companion data was invalid for upsert: ${companionToUpdate.toColumns(true)}");
          }
        }
      }
      _logger.info("ActionHandler: Finished applying final merged cache updates.");
    }

    for (final action in nonScheduleActions) {
      if (action is UpdateCacheAction) continue;
      await _executeSingleAction(action);
    }

    _logger.info("ActionHandler: Finished executing all actions.");
  }

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
          break;
      }
    } catch (e, s) {
      _logger.error("ActionHandler: Failed to execute action $action", e, s);
    }
    return newNotificationId;
  }
}

extension _CopyWithMap on ({int? liveId, int? reminderId}) {
  ({int? liveId, int? reminderId}) copyWith({int? liveId, int? reminderId}) {
    return (liveId: liveId ?? this.liveId, reminderId: reminderId ?? this.reminderId);
  }
}
