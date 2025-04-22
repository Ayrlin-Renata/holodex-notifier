// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_format_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationFormat _$NotificationFormatFromJson(Map<String, dynamic> json) =>
    _NotificationFormat(
      titleTemplate: json['titleTemplate'] as String,
      bodyTemplate: json['bodyTemplate'] as String,
      showThumbnail: json['showThumbnail'] as bool? ?? true,
      showYoutubeLink: json['showYoutubeLink'] as bool? ?? true,
      showHolodexLink: json['showHolodexLink'] as bool? ?? true,
      showSourceLink: json['showSourceLink'] as bool? ?? true,
    );

Map<String, dynamic> _$NotificationFormatToJson(_NotificationFormat instance) =>
    <String, dynamic>{
      'titleTemplate': instance.titleTemplate,
      'bodyTemplate': instance.bodyTemplate,
      'showThumbnail': instance.showThumbnail,
      'showYoutubeLink': instance.showYoutubeLink,
      'showHolodexLink': instance.showHolodexLink,
      'showSourceLink': instance.showSourceLink,
    };

_NotificationFormatConfig _$NotificationFormatConfigFromJson(
  Map<String, dynamic> json,
) => _NotificationFormatConfig(
  formats: _notificationFormatMapFromJson(
    json['formats'] as Map<String, dynamic>,
  ),
  version: (json['version'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$NotificationFormatConfigToJson(
  _NotificationFormatConfig instance,
) => <String, dynamic>{
  'formats': _notificationFormatMapToJson(instance.formats),
  'version': instance.version,
};
