



import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

sealed class NotificationAction {
  const NotificationAction();
}

class ScheduleNotificationAction extends NotificationAction {
  final NotificationInstruction instruction;
  final DateTime scheduleTime;
  final String videoId;
  const ScheduleNotificationAction({required this.instruction, required this.scheduleTime, required this.videoId});
}

class CancelNotificationAction extends NotificationAction {
  final int notificationId;
  final String videoId;
  final NotificationEventType? type;
  const CancelNotificationAction({required this.notificationId, required this.videoId, this.type});
}

class DispatchNotificationAction extends NotificationAction {
  final NotificationInstruction instruction;
  const DispatchNotificationAction({required this.instruction});
}

class UpdateCacheAction extends NotificationAction {
  final String videoId;
  final CachedVideosCompanion companion;
  const UpdateCacheAction({required this.videoId, required this.companion});
}

class UntrackAndCleanAction extends NotificationAction {
  final String videoId;
  final int? liveNotificationId;
  final int? reminderNotificationId;
  const UntrackAndCleanAction({required this.videoId, this.liveNotificationId, this.reminderNotificationId});
}
