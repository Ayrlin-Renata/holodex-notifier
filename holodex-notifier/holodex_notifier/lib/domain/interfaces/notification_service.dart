import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class INotificationService {
  Future<void> initialize();

  Future<int?> showNotification(NotificationInstruction instruction);

  Future<int?> scheduleNotification({required NotificationInstruction instruction, required DateTime scheduledTime});

  Future<void> cancelNotification(int notificationId);

  Future<void> cancelAllNotifications();

  Future<void> reloadFormatConfig();

  Future<Map<Permission, PermissionStatus>> requestRequiredPermissions();
  Future<bool> isBatteryOptimizationDisabled(); 
  Future<bool> requestBatteryOptimizationDisabled(); 
}
