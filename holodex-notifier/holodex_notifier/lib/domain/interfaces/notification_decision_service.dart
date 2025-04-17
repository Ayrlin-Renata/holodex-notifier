import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

abstract class INotificationDecisionService {
  Future<List<NotificationAction>> determineActionsForVideoUpdate({required VideoFull fetchedVideo, required CachedVideo? cachedVideo});

  Future<List<NotificationAction>> determineActionsForChannelSettingChange({
    required String channelId,
    required String settingKey,
    required bool oldValue,
    required bool newValue,
  });

  Future<List<NotificationAction>> determineActionsForApplyGlobalDefaults({
    required List<ChannelSubscriptionSetting> oldSettings,
    required List<ChannelSubscriptionSetting> newSettings,
  });

  Future<List<NotificationAction>> determineActionsForChannelRemoval({required String channelId});

  Future<List<NotificationAction>> determineActionsForReminderLeadTimeChange({required Duration oldLeadTime, required Duration newLeadTime});
}
