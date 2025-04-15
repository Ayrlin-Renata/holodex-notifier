import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart'; // For CachedVideosCompanion

part 'notification_action.freezed.dart';

@freezed
sealed class NotificationAction with _$NotificationAction {
  /// Schedule a platform notification.
  const factory NotificationAction.schedule({
    required NotificationInstruction instruction,
    required DateTime scheduleTime,
    String? videoId, // Added videoId for potential linking/logging
  }) = ScheduleNotificationAction;

  /// Cancel a specific platform notification by its ID.
  const factory NotificationAction.cancel({
    required int notificationId,
    String? videoId, // For logging/context
    NotificationEventType? type, // For context (Live/Reminder)
  }) = CancelNotificationAction;

  /// Dispatch an immediate platform notification.
  const factory NotificationAction.dispatch({
    required NotificationInstruction instruction,
  }) = DispatchNotificationAction;

  /// Update the corresponding video cache entry.
  /// Use a Companion to represent partial updates.
  const factory NotificationAction.updateCache({
    required String videoId,
    required CachedVideosCompanion companion,
  }) = UpdateCacheAction;
}