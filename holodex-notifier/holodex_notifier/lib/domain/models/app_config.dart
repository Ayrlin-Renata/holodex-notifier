import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

@freezed
class AppConfig with _$AppConfig {
  @JsonSerializable(explicitToJson: true) // Needed for nested list
  const factory AppConfig({
    // Include non-sensitive settings
    required int pollFrequencyMinutes,
    required bool notificationGrouping,
    required bool delayNewMedia,
    required int reminderLeadTimeMinutes,

    required List<ChannelSubscriptionSetting> channelSubscriptions,
    // DO NOT include API Key or other sensitive/runtime data like lastPollTime
    // Add version if needed for future compatibility
    @Default(1) int version,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);
}
