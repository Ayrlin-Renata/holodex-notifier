part of 'app_config.dart';

_$AppConfigImpl _$$AppConfigImplFromJson(Map<String, dynamic> json) => _$AppConfigImpl(
  pollFrequencyMinutes: (json['pollFrequencyMinutes'] as num).toInt(),
  notificationGrouping: json['notificationGrouping'] as bool,
  delayNewMedia: json['delayNewMedia'] as bool,
  reminderLeadTimeMinutes: (json['reminderLeadTimeMinutes'] as num).toInt(),
  channelSubscriptions:
      (json['channelSubscriptions'] as List<dynamic>).map((e) => ChannelSubscriptionSetting.fromJson(e as Map<String, dynamic>)).toList(),
  version: (json['version'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$$AppConfigImplToJson(_$AppConfigImpl instance) => <String, dynamic>{
  'pollFrequencyMinutes': instance.pollFrequencyMinutes,
  'notificationGrouping': instance.notificationGrouping,
  'delayNewMedia': instance.delayNewMedia,
  'reminderLeadTimeMinutes': instance.reminderLeadTimeMinutes,
  'channelSubscriptions': instance.channelSubscriptions.map((e) => e.toJson()).toList(),
  'version': instance.version,
};
