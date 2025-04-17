// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\interfaces\notification_service.dart
import 'package:holodex_notifier/domain/models/notification_instruction.dart';

abstract class INotificationService {
  /// Initializes the notification service (e.g., requesting permissions).
  Future<void> initialize();

  /// Sends a notification immediately based on the provided instruction.
  /// Returns the platform-specific notification ID if successful, null otherwise.
  Future<int?> showNotification(NotificationInstruction instruction);

  /// Schedules a notification to be shown at a specific time.
  /// Returns the platform-specific notification ID if successful, null otherwise.
  Future<int?> scheduleNotification({
    required NotificationInstruction instruction,
    required DateTime scheduledTime,
  });

  /// Cancels a previously sent or scheduled notification by its ID.
  /// This covers both immediate and scheduled notifications.
  Future<void> cancelNotification(int notificationId);

  /// Cancels all notifications previously sent or scheduled by this app.
  Future<void> cancelAllNotifications();

  /// Reloads the notification format configuration from the settings.
  /// This is typically called when the format is updated in the UI
  /// to ensure the background service uses the latest settings without restarting.
  Future<void> reloadFormatConfig();
}