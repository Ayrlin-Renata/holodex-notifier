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
    Map<String, String> collectedNamesToCache = {};

    for (final action in actions) {
      if (action is UntrackAndCleanAction) {
        await _executeSingleAction(action);
      } else if (action is ScheduleNotificationAction) {
        if (untrackActions.any((ua) => ua.videoId == action.videoId)) continue;
        int? returnedId = await _executeSingleAction(action);
        if (returnedId != null) {
          final videoId = action.videoId;
          var currentIds = scheduledIdsMap.putIfAbsent(videoId, () => (liveId: null, reminderId: null));
          if (action.instruction.eventType == NotificationEventType.live) {
            scheduledIdsMap[videoId] = currentIds.copyWith(liveId: returnedId);
          } else if (action.instruction.eventType == NotificationEventType.reminder) {
            scheduledIdsMap[videoId] = currentIds.copyWith(reminderId: returnedId);
          }
        }
      } else if (action is CancelNotificationAction) {
        if (untrackActions.any((ua) => ua.videoId == action.videoId)) continue;
        await _executeSingleAction(action);
      } else if (action is UpdateChannelNameCacheAction) {
        collectedNamesToCache.addAll(action.channelNames);
      }
    }

    if (collectedNamesToCache.isNotEmpty) {
      try {
        _logger.debug("ActionHandler: Upserting ${collectedNamesToCache.length} channel names into cache...");
        await _cacheService.upsertChannelNames(collectedNamesToCache);
        _logger.info("ActionHandler: Channel name cache updated.");
      } catch (e, s) {
        _logger.error("ActionHandler: Failed to upsert channel names", e, s);
      }
    }

    Set<String> videosToWrite = {};
    Map<String, List<UpdateCacheAction>> updatesByVideo = {};

    for (final action in actions.whereType<UpdateCacheAction>()) {
      if (untrackActions.any((ua) => ua.videoId == action.videoId)) continue;
      videosToWrite.add(action.videoId);
      updatesByVideo.putIfAbsent(action.videoId, () => []).add(action);
    }
    videosToWrite.addAll(scheduledIdsMap.keys);

    if (videosToWrite.isNotEmpty) {
      _logger.debug("ActionHandler: Preparing final video cache state for ${videosToWrite.length} videos...");
      Map<String, CachedVideosCompanion> finalCompanions = {};

      for (final videoId in videosToWrite) {
        if (untrackActions.any((ua) => ua.videoId == videoId)) continue;

        CachedVideo? currentVideo;
        try {
          currentVideo = await _cacheService.getVideo(videoId);
        } catch (e, s) {
          _logger.warning("ActionHandler: Failed to fetch current state for $videoId during final update prep.", e, s);

          continue;
        }

        var workingCompanion = currentVideo?.toCompanion(false) ?? CachedVideosCompanion(videoId: Value(videoId));

        if (updatesByVideo.containsKey(videoId)) {
          for (final updateAction in updatesByVideo[videoId]!) {
            workingCompanion = workingCompanion.copyWith(
              channelId: updateAction.companion.channelId.present ? updateAction.companion.channelId : workingCompanion.channelId,
              topicId: updateAction.companion.topicId.present ? updateAction.companion.topicId : workingCompanion.topicId,
              status: updateAction.companion.status.present ? updateAction.companion.status : workingCompanion.status,
              startScheduled: updateAction.companion.startScheduled.present ? updateAction.companion.startScheduled : workingCompanion.startScheduled,
              startActual: updateAction.companion.startActual.present ? updateAction.companion.startActual : workingCompanion.startActual,
              availableAt: updateAction.companion.availableAt.present ? updateAction.companion.availableAt : workingCompanion.availableAt,
              videoType: updateAction.companion.videoType.present ? updateAction.companion.videoType : workingCompanion.videoType,
              thumbnailUrl: updateAction.companion.thumbnailUrl.present ? updateAction.companion.thumbnailUrl : workingCompanion.thumbnailUrl,
              certainty: updateAction.companion.certainty.present ? updateAction.companion.certainty : workingCompanion.certainty,
              mentionedChannelIds:
                  updateAction.companion.mentionedChannelIds.present
                      ? updateAction.companion.mentionedChannelIds
                      : workingCompanion.mentionedChannelIds,
              videoTitle: updateAction.companion.videoTitle.present ? updateAction.companion.videoTitle : workingCompanion.videoTitle,
              channelName: updateAction.companion.channelName.present ? updateAction.companion.channelName : workingCompanion.channelName,
              channelAvatarUrl:
                  updateAction.companion.channelAvatarUrl.present ? updateAction.companion.channelAvatarUrl : workingCompanion.channelAvatarUrl,
              isPendingNewMediaNotification:
                  updateAction.companion.isPendingNewMediaNotification.present
                      ? updateAction.companion.isPendingNewMediaNotification
                      : workingCompanion.isPendingNewMediaNotification,
              lastSeenTimestamp:
                  updateAction.companion.lastSeenTimestamp.present ? updateAction.companion.lastSeenTimestamp : workingCompanion.lastSeenTimestamp,
              scheduledLiveNotificationId:
                  updateAction.companion.scheduledLiveNotificationId.present
                      ? updateAction.companion.scheduledLiveNotificationId
                      : workingCompanion.scheduledLiveNotificationId,
              lastLiveNotificationSentTime:
                  updateAction.companion.lastLiveNotificationSentTime.present
                      ? updateAction.companion.lastLiveNotificationSentTime
                      : workingCompanion.lastLiveNotificationSentTime,
              scheduledReminderNotificationId:
                  updateAction.companion.scheduledReminderNotificationId.present
                      ? updateAction.companion.scheduledReminderNotificationId
                      : workingCompanion.scheduledReminderNotificationId,
              scheduledReminderTime:
                  updateAction.companion.scheduledReminderTime.present
                      ? updateAction.companion.scheduledReminderTime
                      : workingCompanion.scheduledReminderTime,
              userDismissedAt:
                  updateAction.companion.userDismissedAt.present ? updateAction.companion.userDismissedAt : workingCompanion.userDismissedAt,
              sentMentionTargetIds:
                  updateAction.companion.sentMentionTargetIds.present
                      ? updateAction.companion.sentMentionTargetIds
                      : workingCompanion.sentMentionTargetIds,
            );
          }
        }

        if (scheduledIdsMap.containsKey(videoId)) {
          final scheduledIds = scheduledIdsMap[videoId]!;
          if (scheduledIds.liveId != null &&
              workingCompanion.scheduledLiveNotificationId.present &&
              workingCompanion.scheduledLiveNotificationId.value == -1) {
            workingCompanion = workingCompanion.copyWith(scheduledLiveNotificationId: Value(scheduledIds.liveId));
          }
          if (scheduledIds.reminderId != null &&
              workingCompanion.scheduledReminderNotificationId.present &&
              workingCompanion.scheduledReminderNotificationId.value == -1) {
            workingCompanion = workingCompanion.copyWith(scheduledReminderNotificationId: Value(scheduledIds.reminderId));
          }
        }

        if (workingCompanion.scheduledLiveNotificationId.present && workingCompanion.scheduledLiveNotificationId.value == -1) {
          workingCompanion = workingCompanion.copyWith(scheduledLiveNotificationId: const Value(null));
        }
        if (workingCompanion.scheduledReminderNotificationId.present && workingCompanion.scheduledReminderNotificationId.value == -1) {
          workingCompanion = workingCompanion.copyWith(scheduledReminderNotificationId: const Value(null));
        }

        if (currentVideo == null) {
          workingCompanion = workingCompanion.copyWith(
            status: workingCompanion.status.present ? workingCompanion.status : const Value('unknown'),
            availableAt: workingCompanion.availableAt.present ? workingCompanion.availableAt : Value(DateTime.now().toIso8601String()),
            lastSeenTimestamp:
                workingCompanion.lastSeenTimestamp.present ? workingCompanion.lastSeenTimestamp : Value(DateTime.now().millisecondsSinceEpoch),
          );
        }

        finalCompanions[videoId] = workingCompanion;
      }

      _logger.debug("ActionHandler: Persisting final video cache state for ${finalCompanions.length} videos...");
      for (final entry in finalCompanions.entries) {
        final videoId = entry.key;
        final finalCompanion = entry.value;
        try {
          _logger.debug("ActionHandler: Executing cache UPSERT for $videoId: ${finalCompanion.toColumns(true)}");

          await _cacheService.upsertVideo(finalCompanion.copyWith(videoId: Value(videoId)));
          _logger.debug("ActionHandler: Cache upsert operation finished for video $videoId.");
        } catch (e, s) {
          _logger.error("ActionHandler: Failed to execute cache upsert for video $videoId", e, s);
          if (e is InvalidDataException) {
            _logger.error("ActionHandler: The companion data was invalid for upsert: ${finalCompanion.toColumns(true)}");
          }
        }
      }
      _logger.info("ActionHandler: Finished applying final video cache updates.");
    }

    for (final action in actions.whereType<DispatchNotificationAction>()) {
      if (untrackActions.any((ua) => ua.videoId == action.instruction.videoId)) continue;
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
          _logger.trace("ActionHandler [SingleExec]: UpdateCache action handled in batch. No action needed here.");
          break;
        case UpdateChannelNameCacheAction():
          _logger.trace("ActionHandler [SingleExec]: UpdateChannelNameCache action handled in batch. No action needed here.");
          break;

        case UntrackAndCleanAction(:final videoId, :final liveNotificationId, :final reminderNotificationId):
          _logger.info("ActionHandler [SingleExec]: Executing UntrackAndClean for video $videoId.");

          if (liveNotificationId != null) {
            try {
              _logger.debug("ActionHandler ($videoId): Untrack - Cancelling Live ID $liveNotificationId");
              await _notificationService.cancelNotification(liveNotificationId);
            } catch (e, s) {
              _logger.error("ActionHandler ($videoId): Untrack - Failed to cancel live notification $liveNotificationId", e, s);
            }
          }
          if (reminderNotificationId != null) {
            try {
              _logger.debug("ActionHandler ($videoId): Untrack - Cancelling Reminder ID $reminderNotificationId");
              await _notificationService.cancelNotification(reminderNotificationId);
            } catch (e, s) {
              _logger.error("ActionHandler ($videoId): Untrack - Failed to cancel reminder notification $reminderNotificationId", e, s);
            }
          }

          try {
            _logger.debug("ActionHandler ($videoId): Untrack - Deleting from cache.");
            await _cacheService.deleteVideo(videoId);
          } catch (e, s) {
            _logger.error("ActionHandler ($videoId): Untrack - Failed to delete video from cache", e, s);
          }
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
