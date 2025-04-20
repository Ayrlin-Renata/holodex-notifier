// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => _AppConfig(
  pollFrequencyMinutes: (json['pollFrequencyMinutes'] as num).toInt(),
  notificationGrouping: json['notificationGrouping'] as bool,
  delayNewMedia: json['delayNewMedia'] as bool,
  reminderLeadTimeMinutes: (json['reminderLeadTimeMinutes'] as num).toInt(),
  channelSubscriptions:
      (json['channelSubscriptions'] as List<dynamic>).map((e) => ChannelSubscriptionSetting.fromJson(e as Map<String, dynamic>)).toList(),
  version: (json['version'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$AppConfigToJson(_AppConfig instance) => <String, dynamic>{
  'pollFrequencyMinutes': instance.pollFrequencyMinutes,
  'notificationGrouping': instance.notificationGrouping,
  'delayNewMedia': instance.delayNewMedia,
  'reminderLeadTimeMinutes': instance.reminderLeadTimeMinutes,
  'channelSubscriptions': instance.channelSubscriptions.map((e) => e.toJson()).toList(),
  'version': instance.version,
};
