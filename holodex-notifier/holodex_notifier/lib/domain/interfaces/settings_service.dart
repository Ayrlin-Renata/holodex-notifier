import 'package:holodex_notifier/domain/models/app_config.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';

abstract class ISettingsService {
  Future<void> initialize();

  Future<Duration> getPollFrequency();

  Future<void> setPollFrequency(Duration frequency);

  Future<bool> getNotificationGrouping();

  Future<void> setNotificationGrouping(bool enabled);

  Future<bool> getDelayNewMedia();

  Future<void> setDelayNewMedia(bool enabled);
  Future<Duration> getReminderLeadTime();
  Future<void> setReminderLeadTime(Duration leadTime);

  Future<DateTime?> getLastPollTime();

  Future<void> setLastPollTime(DateTime time);

  Future<String?> getApiKey();

  Future<void> setApiKey(String? apiKey);

  Future<List<ChannelSubscriptionSetting>> getChannelSubscriptions();

  Future<void> saveChannelSubscriptions(List<ChannelSubscriptionSetting> channels);

  Future<void> updateChannelAvatar(String channelId, String? newAvatarUrl);

  Future<bool> getMainServicesReady();

  Future<void> setMainServicesReady(bool ready);

  Future<bool> getIsFirstLaunch();
  Future<void> setIsFirstLaunch(bool isFirst);

  Future<AppConfig> exportConfiguration();

  Future<bool> importConfiguration(AppConfig config);

  Future<NotificationFormatConfig> getNotificationFormatConfig();

  Future<void> setNotificationFormatConfig(NotificationFormatConfig config);

  Future<Set<NotificationEventType>> getScheduledFilterTypes();
  Future<void> setScheduledFilterTypes(Set<NotificationEventType> types);

  Set<NotificationEventType> getScheduledFilterTypesSync();
}
