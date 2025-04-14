// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_subscription_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChannelSubscriptionSettingImpl _$$ChannelSubscriptionSettingImplFromJson(
        Map<String, dynamic> json) =>
    _$ChannelSubscriptionSettingImpl(
      channelId: json['channelId'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      notifyNewMedia: json['notifyNewMedia'] as bool? ?? true,
      notifyMentions: json['notifyMentions'] as bool? ?? true,
      notifyLive: json['notifyLive'] as bool? ?? true,
      notifyUpdates: json['notifyUpdates'] as bool? ?? true,
    );

Map<String, dynamic> _$$ChannelSubscriptionSettingImplToJson(
        _$ChannelSubscriptionSettingImpl instance) =>
    <String, dynamic>{
      'channelId': instance.channelId,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'notifyNewMedia': instance.notifyNewMedia,
      'notifyMentions': instance.notifyMentions,
      'notifyLive': instance.notifyLive,
      'notifyUpdates': instance.notifyUpdates,
    };
