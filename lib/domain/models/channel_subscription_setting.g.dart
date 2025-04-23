// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_subscription_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChannelSubscriptionSetting _$ChannelSubscriptionSettingFromJson(Map<String, dynamic> json) => _ChannelSubscriptionSetting(
  channelId: json['channelId'] as String,
  name: json['name'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  notifyNewMedia: json['notifyNewMedia'] as bool? ?? true,
  notifyMentions: json['notifyMentions'] as bool? ?? true,
  notifyLive: json['notifyLive'] as bool? ?? true,
  notifyUpdates: json['notifyUpdates'] as bool? ?? true,
  notifyMembersOnly: json['notifyMembersOnly'] as bool? ?? true,
  notifyClips: json['notifyClips'] as bool? ?? true,
);

Map<String, dynamic> _$ChannelSubscriptionSettingToJson(_ChannelSubscriptionSetting instance) => <String, dynamic>{
  'channelId': instance.channelId,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'notifyNewMedia': instance.notifyNewMedia,
  'notifyMentions': instance.notifyMentions,
  'notifyLive': instance.notifyLive,
  'notifyUpdates': instance.notifyUpdates,
  'notifyMembersOnly': instance.notifyMembersOnly,
  'notifyClips': instance.notifyClips,
};
