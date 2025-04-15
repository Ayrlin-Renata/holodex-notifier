// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\models\channel_subscription_setting.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_subscription_setting.freezed.dart';
part 'channel_subscription_setting.g.dart';

@freezed
class ChannelSubscriptionSetting with _$ChannelSubscriptionSetting {
  // Apply JsonSerializable for persistence via SettingsService (e.g., saving to SharedPreferences as JSON)
  @JsonSerializable()
  const factory ChannelSubscriptionSetting({
    // Identifying information for the channel
    required String channelId,
    required String name,
    String? avatarUrl, // URL to the channel's avatar image
    // Notification toggles matching the UI
    @Default(true) bool notifyNewMedia,
    @Default(true) bool notifyMentions,
    @Default(true) bool notifyLive,
    @Default(true) bool notifyUpdates,
    @Default(true) bool notifyMembersOnly,
    @Default(true) bool notifyClips,
  }) = _ChannelSubscriptionSetting;

  // Factory constructor for creating a new instance from JSON data
  factory ChannelSubscriptionSetting.fromJson(Map<String, dynamic> json) => _$ChannelSubscriptionSettingFromJson(json);
}
