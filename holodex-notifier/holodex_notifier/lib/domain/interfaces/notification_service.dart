import 'package:holodex_notifier/domain/models/notification_instruction.dart'; // Import the instruction model

abstract class INotificationService {
  Future<void> initialize();

  // Use the specific instruction type
  Future<void> showNotification(NotificationInstruction instruction);

  Future<int?> scheduleNotification({
    required String videoId,
    required DateTime scheduledTime,
    required String payload,
    required String title,
    required String channelName,
    required NotificationEventType eventType,
  });

  Future<void> cancelScheduledNotification(int notificationId);
  Future<void> cancelAllNotifications();

  // Stream to listen for notification tap events (payload can be videoId)
  Stream<String?> get notificationTapStream;
}