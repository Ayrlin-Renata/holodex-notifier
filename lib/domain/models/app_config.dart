import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

@freezed
abstract class AppConfig with _$AppConfig {
  @JsonSerializable(explicitToJson: true)
  const factory AppConfig({
    required int pollFrequencyMinutes,
    required bool notificationGrouping,
    required bool delayNewMedia,
    required int reminderLeadTimeMinutes,

    required List<ChannelSubscriptionSetting> channelSubscriptions,
    @Default(1) int version,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);
}
