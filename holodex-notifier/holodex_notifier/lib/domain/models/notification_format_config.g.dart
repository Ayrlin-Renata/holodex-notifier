// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_format_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationFormatImpl _$$NotificationFormatImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationFormatImpl(
      titleTemplate: json['titleTemplate'] as String,
      bodyTemplate: json['bodyTemplate'] as String,
    );

Map<String, dynamic> _$$NotificationFormatImplToJson(
        _$NotificationFormatImpl instance) =>
    <String, dynamic>{
      'titleTemplate': instance.titleTemplate,
      'bodyTemplate': instance.bodyTemplate,
    };

_$NotificationFormatConfigImpl _$$NotificationFormatConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationFormatConfigImpl(
      formats: _notificationFormatMapFromJson(
          json['formats'] as Map<String, dynamic>),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$NotificationFormatConfigImplToJson(
        _$NotificationFormatConfigImpl instance) =>
    <String, dynamic>{
      'formats': _notificationFormatMapToJson(instance.formats),
      'version': instance.version,
    };
