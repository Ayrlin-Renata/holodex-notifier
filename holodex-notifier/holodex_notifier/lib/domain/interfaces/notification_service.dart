import 'package:holodex_notifier/domain/models/notification_instruction.dart';

abstract class INotificationService {
  Future<void> initialize();

  Future<int?> showNotification(NotificationInstruction instruction);

  Future<int?> scheduleNotification({required NotificationInstruction instruction, required DateTime scheduledTime});

  Future<void> cancelNotification(int notificationId);

  Future<void> cancelAllNotifications();

  Future<void> reloadFormatConfig();
  Future<bool> requestNotificationPermissions();
}
