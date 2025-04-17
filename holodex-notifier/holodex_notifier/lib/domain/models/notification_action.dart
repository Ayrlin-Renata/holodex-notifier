import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

part 'notification_action.freezed.dart';

@freezed
sealed class NotificationAction with _$NotificationAction {
  const factory NotificationAction.schedule({required NotificationInstruction instruction, required DateTime scheduleTime, String? videoId}) =
      ScheduleNotificationAction;

  const factory NotificationAction.cancel({required int notificationId, String? videoId, NotificationEventType? type}) = CancelNotificationAction;

  const factory NotificationAction.dispatch({required NotificationInstruction instruction}) = DispatchNotificationAction;

  const factory NotificationAction.updateCache({required String videoId, required CachedVideosCompanion companion}) = UpdateCacheAction;
}
