import 'package:holodex_notifier/domain/models/notification_action.dart';

abstract class INotificationActionHandler {
  Future<void> executeActions(List<NotificationAction> actions);
}
