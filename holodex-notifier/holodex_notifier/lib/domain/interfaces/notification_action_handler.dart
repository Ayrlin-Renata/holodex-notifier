import 'package:holodex_notifier/domain/models/notification_action.dart';

/// Executes a list of notification-related actions.
abstract class INotificationActionHandler {
  Future<void> executeActions(List<NotificationAction> actions);
}