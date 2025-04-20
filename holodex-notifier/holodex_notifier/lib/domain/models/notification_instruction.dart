import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_instruction.freezed.dart';

enum NotificationEventType { newMedia, live, update, mention, reminder }

@freezed
abstract class NotificationInstruction with _$NotificationInstruction {
  const factory NotificationInstruction({
    required String videoId,
    required NotificationEventType eventType,
    required String channelId,
    required String channelName,
    required String videoTitle,
    String? videoType,
    String? channelAvatarUrl,
    required DateTime availableAt,

    String? mentionTargetChannelId,
    String? mentionTargetChannelName,
    List<String>? mentionedChannelNames,

    String? videoThumbnailUrl,
    String? videoSourceLink,
  }) = _NotificationInstruction;
}
