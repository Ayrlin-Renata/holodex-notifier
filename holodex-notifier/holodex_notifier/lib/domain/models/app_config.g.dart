// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppConfigImpl _$$AppConfigImplFromJson(Map<String, dynamic> json) =>
    _$AppConfigImpl(
      pollFrequencyMinutes: (json['pollFrequencyMinutes'] as num).toInt(),
      notificationGrouping: json['notificationGrouping'] as bool,
      delayNewMedia: json['delayNewMedia'] as bool,
      channelSubscriptions: (json['channelSubscriptions'] as List<dynamic>)
          .map((e) =>
              ChannelSubscriptionSetting.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$AppConfigImplToJson(_$AppConfigImpl instance) =>
    <String, dynamic>{
      'pollFrequencyMinutes': instance.pollFrequencyMinutes,
      'notificationGrouping': instance.notificationGrouping,
      'delayNewMedia': instance.delayNewMedia,
      'channelSubscriptions':
          instance.channelSubscriptions.map((e) => e.toJson()).toList(),
      'version': instance.version,
    };
