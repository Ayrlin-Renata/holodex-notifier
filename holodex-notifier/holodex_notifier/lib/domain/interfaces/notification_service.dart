// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\interfaces\notification_service.dart
import 'package:holodex_notifier/domain/models/notification_instruction.dart';

abstract class INotificationService {
  Future<void> initialize();

  /// Shows an immediate notification based on the instruction.
  Future<void> showNotification(NotificationInstruction instruction);

  /// Schedules a future notification.
  /// Formatting (title/body) happens inside the implementation based on the instruction.
  /// Returns the platform notification ID if successful, null otherwise.
  Future<int?> scheduleNotification({
    required NotificationInstruction instruction, // Use the instruction model
    required DateTime scheduledTime, // Specific time to show the notification
  });

  Future<void> cancelScheduledNotification(int notificationId);
  Future<void> cancelAllNotifications();

  // Stream to listen for notification tap events (payload can be videoId)
  Stream<String?> get notificationTapStream;
}