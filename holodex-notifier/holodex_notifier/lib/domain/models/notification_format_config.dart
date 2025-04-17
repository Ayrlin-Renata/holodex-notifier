import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';

part 'notification_format_config.freezed.dart';
part 'notification_format_config.g.dart';

@freezed
@JsonSerializable()
class NotificationFormat with _$NotificationFormat {
  const factory NotificationFormat({
    required String titleTemplate,
    required String bodyTemplate,
    @Default(true) bool showThumbnail,
    @Default(true) bool showYoutubeLink,
    @Default(true) bool showHolodexLink,
    @Default(true) bool showSourceLink,
  }) = _NotificationFormat;

  factory NotificationFormat.fromJson(Map<String, dynamic> json) => _$NotificationFormatFromJson(json);
}

@freezed
@JsonSerializable(explicitToJson: true)
class NotificationFormatConfig with _$NotificationFormatConfig {
  const factory NotificationFormatConfig({
    @JsonKey(fromJson: _notificationFormatMapFromJson, toJson: _notificationFormatMapToJson)
    required Map<NotificationEventType, NotificationFormat> formats,
    @Default(1) int version,
  }) = _NotificationFormatConfig;

  factory NotificationFormatConfig.fromJson(Map<String, dynamic> json) => _$NotificationFormatConfigFromJson(json);

  factory NotificationFormatConfig.defaultConfig() {
    return NotificationFormatConfig(
      formats: {
        NotificationEventType.newMedia: const NotificationFormat(
          titleTemplate: 'New {mediaType} - {mediaDateYMD} {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
        NotificationEventType.mention: const NotificationFormat(
          titleTemplate: 'Mentioned in {mediaType} - {mediaDateYMD} {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
        NotificationEventType.live: const NotificationFormat(
          titleTemplate: '🔴 {mediaTypeCaps} LIVE NOW - {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
        NotificationEventType.reminder: const NotificationFormat(
          titleTemplate: 'Live in {relativeTime}: {mediaType} - {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
        NotificationEventType.update: const NotificationFormat(
          titleTemplate: '⚠️ Update for {mediaType} - {mediaDateYMD} {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
      },
      version: 1,
    );
  }
}

Map<NotificationEventType, NotificationFormat> _notificationFormatMapFromJson(Map<String, dynamic> json) {
  return json.map((key, value) {
    final eventType = NotificationEventType.values.firstWhere((e) => e.name == key, orElse: () => NotificationEventType.newMedia);
    return MapEntry(eventType, NotificationFormat.fromJson(value as Map<String, dynamic>));
  });
}

Map<String, dynamic> _notificationFormatMapToJson(Map<NotificationEventType, NotificationFormat> map) {
  return map.map((key, value) => MapEntry(key.name, value.toJson()));
}
