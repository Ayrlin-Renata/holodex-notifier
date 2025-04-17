import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart'; // Import NotificationEventType

part 'notification_format_config.freezed.dart';
part 'notification_format_config.g.dart';

/// Represents the format template for a single notification type.
@freezed
class NotificationFormat with _$NotificationFormat {
  @JsonSerializable()
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

/// Holds the format configurations for all notification event types.
@freezed
class NotificationFormatConfig with _$NotificationFormatConfig {
  @JsonSerializable(explicitToJson: true) // Needed for nested maps/objects
  const factory NotificationFormatConfig({
    // Use a Map where the key is NotificationEventType and value is the format.
    // Need a custom converter because NotificationEventType cannot be a Map key directly in JSON.
    @JsonKey(fromJson: _notificationFormatMapFromJson, toJson: _notificationFormatMapToJson)
    required Map<NotificationEventType, NotificationFormat> formats,
    @Default(1) int version, // For future schema changes
  }) = _NotificationFormatConfig;

  factory NotificationFormatConfig.fromJson(Map<String, dynamic> json) => _$NotificationFormatConfigFromJson(json);

  /// Provides default configurations based on the user's specification.
  factory NotificationFormatConfig.defaultConfig() {
    return NotificationFormatConfig(
      formats: {
        NotificationEventType.newMedia: const NotificationFormat(
          // Image: "[Channel Image]" - Handled By Service
          // Title: "New [Media Type] - [Media Time] - [Channel Name]"
          // Content: "[Media Title]"
          titleTemplate: 'New {mediaType} - {mediaDateYMD} {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
        NotificationEventType.mention: const NotificationFormat(
          // Image: "[Channel Image]" - Handled By Service
          // Title: "Mentioned in [Media Type] - [Media Time] - [Channel Name]"
          // Content: "[Media Title]"
          titleTemplate: 'Mentioned in {mediaType} - {mediaDateYMD} {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
        NotificationEventType.live: const NotificationFormat(
          // Image: "[Channel Image]" - Handled By Service
          // Title: "🔴 [Media Type (all caps)] LIVE NOW - [Media Time] - [Channel Name]"
          // Content: "[Media Title]"
          titleTemplate: '🔴 {mediaTypeCaps} LIVE NOW - {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
        NotificationEventType.reminder: const NotificationFormat(
          // Image: "[Channel Image]" - Handled By Service
          // Title: "Live in [Relative to Media Time]: [Media Type] - [Media Time] - [Channel Name]"
          // Content: "[Media Title]"
          titleTemplate: 'Live in {relativeTime}: {mediaType} - {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
        NotificationEventType.update: const NotificationFormat(
          // Image: "[Channel Image]" - Handled By Service
          // Title: "⚠️ Update for [Media Type] - [Media Time] - [Channel Name]"
          // Content: "[Media Title]"
          titleTemplate: '⚠️ Update for {mediaType} - {mediaDateYMD} {mediaTime} - {channelName}',
          bodyTemplate: '{mediaTitle}',
        ),
      },
      version: 1,
    );
  }
}

// --- Custom JSON Converters for Map<NotificationEventType, NotificationFormat> ---

Map<NotificationEventType, NotificationFormat> _notificationFormatMapFromJson(Map<String, dynamic> json) {
  return json.map((key, value) {
    final eventType = NotificationEventType.values.firstWhere((e) => e.name == key, orElse: () => NotificationEventType.newMedia); // Default fallback
    return MapEntry(eventType, NotificationFormat.fromJson(value as Map<String, dynamic>));
  });
}

Map<String, dynamic> _notificationFormatMapToJson(Map<NotificationEventType, NotificationFormat> map) {
  return map.map((key, value) => MapEntry(key.name, value.toJson()));
}
