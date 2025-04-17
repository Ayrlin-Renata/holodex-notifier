import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_subscription_setting.freezed.dart';
part 'channel_subscription_setting.g.dart';

@freezed
@JsonSerializable()
class ChannelSubscriptionSetting with _$ChannelSubscriptionSetting {
  const factory ChannelSubscriptionSetting({
    required String channelId,
    required String name,
    String? avatarUrl,
    @Default(true) bool notifyNewMedia,
    @Default(true) bool notifyMentions,
    @Default(true) bool notifyLive,
    @Default(true) bool notifyUpdates,
    @Default(true) bool notifyMembersOnly,
    @Default(true) bool notifyClips,
  }) = _ChannelSubscriptionSetting;

  factory ChannelSubscriptionSetting.fromJson(Map<String, dynamic> json) => _$ChannelSubscriptionSettingFromJson(json);
}
