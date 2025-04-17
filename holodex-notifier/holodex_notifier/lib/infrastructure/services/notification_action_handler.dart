import 'package:drift/drift.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';

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

    // Consider potential batching for cache updates
    List<UpdateCacheAction> cacheUpdates = actions.whereType<UpdateCacheAction>().toList();
    List<NotificationAction> otherActions = actions.where((a) => a is! UpdateCacheAction).toList();
    // Execute non-cache actions first
    Map<String, int> scheduledNotificationIds = {}; // {{ Store successfully scheduled IDs }}
    for (final action in otherActions) {
      // {{ Capture the returned ID from schedule action }}
      int? returnedId = await _executeSingleAction(action);
      if (action is ScheduleNotificationAction && returnedId != null && action.videoId != null) {
        scheduledNotificationIds[action.videoId!] = returnedId; // Store ID by videoId
      }
    }

    if (cacheUpdates.isNotEmpty) {
      _logger.debug("ActionHandler: Applying ${cacheUpdates.length} cache updates...");
      for (var updateAction in cacheUpdates) {
        final videoId = updateAction.videoId;
        var companionToUpdate = updateAction.companion; // Start with the companion from the action

        // Check if this update corresponds to a video for which we just scheduled a notification
        // NOTE: This assumes DecisionService uses placeholder (-1) for schedule intent.
        bool updatedIdFromSchedule = false;
        if (scheduledNotificationIds.containsKey(videoId)) {
          int actualId = scheduledNotificationIds[videoId]!;
          // Determine if it was Live or Reminder based on placeholder/other fields
          // This is fragile. Ideally DecisionService would provide type context in Schedule action.
          // Let's assume for now: If scheduledLiveNotificationId was -1, update it. If scheduledReminderNotificationId was -1, update it.
          if (companionToUpdate.scheduledLiveNotificationId.present && companionToUpdate.scheduledLiveNotificationId.value == -1) {
            _logger.debug("ActionHandler: Injecting actual SCHEDULED LIVE ID $actualId into cache update for $videoId");
            companionToUpdate = companionToUpdate.copyWith(scheduledLiveNotificationId: Value(actualId));
            updatedIdFromSchedule = true;
          } else if (companionToUpdate.scheduledReminderNotificationId.present && companionToUpdate.scheduledReminderNotificationId.value == -1) {
            _logger.debug("ActionHandler: Injecting actual SCHEDULED REMINDER ID $actualId into cache update for $videoId");
            companionToUpdate = companionToUpdate.copyWith(scheduledReminderNotificationId: Value(actualId));
            updatedIdFromSchedule = true;
          }
        }
        // If we didn't inject an ID, ensure placeholders are nulled out if they exist
        if (!updatedIdFromSchedule) {
          if (companionToUpdate.scheduledLiveNotificationId.present && companionToUpdate.scheduledLiveNotificationId.value == -1) {
            companionToUpdate = companionToUpdate.copyWith(scheduledLiveNotificationId: const Value(null));
          }
          if (companionToUpdate.scheduledReminderNotificationId.present && companionToUpdate.scheduledReminderNotificationId.value == -1) {
            companionToUpdate = companionToUpdate.copyWith(scheduledReminderNotificationId: const Value(null));
          }
        }

        try {
          int updatedRows = await _cacheService.updateVideo(videoId, companionToUpdate);
          if (updatedRows > 0) {
            _logger.debug("ActionHandler: Cache updated for video $videoId.");
          } else {
            // This might happen if the base record insert failed earlier but the poll cycle continued
            _logger.warning("ActionHandler: Cache update for $videoId affected 0 rows. Record might not exist.");
          }
        } catch (e, s) {
          // Logging error remains the same
          _logger.error("ActionHandler: Failed to execute cache update for video $videoId", e, s);
        }
      }
      _logger.info("ActionHandler: Finished applying cache updates.");
    }
    _logger.info("ActionHandler: Finished executing all actions.");
  }

  Future<int?> _executeSingleAction(NotificationAction action) async {
    int? newNotificationId; // Variable to store the ID from schedule action
    try {
      switch (action) {
        case ScheduleNotificationAction(:final instruction, :final scheduleTime, :final videoId):
          _logger.debug("ActionHandler: Scheduling notification for $videoId at $scheduleTime.");
          // {{ Store the result }}
          newNotificationId = await _notificationService.scheduleNotification(instruction: instruction, scheduledTime: scheduleTime);
          if (newNotificationId == null) {
            _logger.warning("ActionHandler: Scheduling returned null ID for $videoId.");
          }
          break; // Return ID below

        case CancelNotificationAction(:final notificationId, :final videoId, :final type):
          _logger.debug("ActionHandler: Cancelling notification ID $notificationId (Type: ${type?.name ?? 'Unknown'}) for video $videoId.");
          await _notificationService.cancelNotification(notificationId);
          break;

        case DispatchNotificationAction(:final instruction):
          _logger.debug("ActionHandler: Dispatching notification for ${instruction.videoId} (Type: ${instruction.eventType}).");
          await _notificationService.showNotification(instruction);
          break;

        case UpdateCacheAction():
          // Already handled in the calling loop
          break;
      }
    } catch (e, s) {
      // Logging remains the same
      _logger.error("ActionHandler: Failed to execute action $action", e, s);
    }
    return newNotificationId; // Return the captured ID (or null)
  }
}
