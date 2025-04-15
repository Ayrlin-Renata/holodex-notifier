import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_instruction.freezed.dart';

enum NotificationEventType {
  newMedia,
  live,
  update,
  mention,
  reminder,
}

@freezed
class NotificationInstruction with _$NotificationInstruction {
  const factory NotificationInstruction({
    required String videoId,
    required NotificationEventType eventType,
    required String channelId,
    required String channelName,
    required String videoTitle,
    String? channelAvatarUrl, // Optional for notification display

    // Fields specific to certain types (optional)
    String? mentionTargetChannelId, // For Mention event
    String? mentionTargetChannelName, // For Mention event

  }) = _NotificationInstruction;

  // Note: No fromJson/toJson needed unless you plan to serialize these instructions themselves.
}