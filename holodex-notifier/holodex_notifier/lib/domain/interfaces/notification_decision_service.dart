import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

/// Determines required notification actions based on events and state.
abstract class INotificationDecisionService {
  /// Determines actions needed based on a video update from the poller.
  Future<List<NotificationAction>> determineActionsForVideoUpdate({
    required VideoFull fetchedVideo,
    required CachedVideo? cachedVideo, // Previous state from cache
  });

  /// Determines actions needed when a channel-specific setting changes.
  Future<List<NotificationAction>> determineActionsForChannelSettingChange({
    required String channelId,
    required String settingKey, // e.g., 'notifyLive', 'notifyMembersOnly'
    required bool oldValue,
    required bool newValue,
  });

   /// Determines actions needed when global defaults are applied, affecting multiple channels.
   Future<List<NotificationAction>> determineActionsForApplyGlobalDefaults({
         required List<ChannelSubscriptionSetting> oldSettings, // Settings BEFORE applying
         required List<ChannelSubscriptionSetting> newSettings, // Settings AFTER applying
   });

   /// Determines actions needed when a specific channel is removed.
   Future<List<NotificationAction>> determineActionsForChannelRemoval({
       required String channelId,
   });

   /// Determines actions needed when the global reminder lead time changes.
   Future<List<NotificationAction>> determineActionsForReminderLeadTimeChange({
       required Duration oldLeadTime,
       required Duration newLeadTime,
   });
}