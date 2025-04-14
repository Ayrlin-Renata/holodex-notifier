import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:holodex_notifier/ui/screens/settings_screen.dart'; // Required for invoking

/// Controller handling actions related to settings and channels.
class AppController {
  final Ref _ref;
  final ISettingsService _settingsService;
  final ILoggingService _loggingService;
  final ICacheService _cacheService; // Add CacheService
  final INotificationService _notificationService; // Add NotificationService

  // Updated constructor
  AppController(this._ref, this._settingsService, this._loggingService, this._cacheService, this._notificationService); // Add services to constructor

  /// Adds a channel based on search result data.
  Future<void> addChannel(Channel channelData) async {
    _loggingService.info('AppController: Adding channel ${channelData.id}: ${channelData.name}');
    try {
      final defaultNewMedia = _ref.read(globalNewMediaDefaultProvider);
      final defaultMentions = _ref.read(globalMentionsDefaultProvider);
      final defaultLive = _ref.read(globalLiveDefaultProvider);
      final defaultUpdate = _ref.read(globalUpdateDefaultProvider);

      final newSetting = ChannelSubscriptionSetting(
        channelId: channelData.id,
        name: channelData.name,
        avatarUrl: channelData.photo,
        notifyNewMedia: defaultNewMedia,
        notifyMentions: defaultMentions,
        notifyLive: defaultLive,
        notifyUpdates: defaultUpdate,
      );

      _ref.read(channelListProvider.notifier).addChannel(newSetting);
      _loggingService.debug('AppController: Channel ${channelData.id} added to state.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to add channel ${channelData.id}', e, s);
    }
  }

  /// Removes a channel by its ID and cleans up related scheduled notifications.
  Future<void> removeChannel(String channelId) async {
    _loggingService.info('AppController: Removing channel $channelId and cleaning up scheduled notifications.');
    try {
      // --- Cleanup Logic Start ---
      _loggingService.debug('AppController: Fetching scheduled videos for channel $channelId from cache...');
      final scheduledVideos = await _cacheService.getScheduledVideos(); // Get all scheduled videos
       _loggingService.debug('AppController: Found ${scheduledVideos.length} total scheduled videos.');

      // Filter for the specific channel being removed
      final channelScheduledVideos = scheduledVideos.where((v) => v.channelId == channelId).toList();
      _loggingService.debug('AppController: Found ${channelScheduledVideos.length} scheduled videos specifically for channel $channelId.');


      if (channelScheduledVideos.isNotEmpty) {
        _loggingService.info('AppController: Cancelling ${channelScheduledVideos.length} scheduled notification(s) for channel $channelId...');
        for (final video in channelScheduledVideos) {
          if (video.scheduledLiveNotificationId != null) {
             _loggingService.debug('AppController: Cancelling notification ID ${video.scheduledLiveNotificationId} for video ${video.videoId}');
            try {
              // Cancel platform notification
              await _notificationService.cancelScheduledNotification(video.scheduledLiveNotificationId!);
              // Update cache entry to reflect cancellation
              await _cacheService.updateScheduledNotificationId(video.videoId, null);
               _loggingService.debug('AppController: Successfully cancelled and updated cache for video ${video.videoId}.');
            } catch (e, s) {
              _loggingService.error(
                'AppController: Error cancelling notification ID ${video.scheduledLiveNotificationId} or updating cache for video ${video.videoId}',
                e,
                s,
              );
              // Continue to next video even if one fails? Yes.
            }
          } else {
             _loggingService.warning(
                'AppController: Scheduled video ${video.videoId} found in cache query but had null scheduledLiveNotificationId. Skipping cancellation.',
             );
          }
        }
        _loggingService.info('AppController: Finished cancelling scheduled notifications for channel $channelId.');
      }
      // --- Cleanup Logic End ---

      // Proceed with removing the channel from settings
      _ref.read(channelListProvider.notifier).removeChannel(channelId);
      _loggingService.debug('AppController: Channel $channelId removed from state.');

      // Refresh the UI list after cleanup and removal
      // ignore: unused_result
      _ref.refresh(scheduledNotificationsProvider);
      _loggingService.debug('AppController: Refreshed scheduled notifications provider.');

    } catch (e, s) {
      _loggingService.error('AppController: Failed to remove channel $channelId', e, s);
      // Optionally rethrow or show an error to the user
    }
  }


  /// Updates a specific notification toggle for a given channel.
  Future<void> updateChannelNotificationSetting(String channelId, String settingKey, bool value) async {
    _loggingService.info('AppController: Updating $settingKey for channel $channelId to $value');
    try {
      final notifier = _ref.read(channelListProvider.notifier);
      switch (settingKey) {
        case 'notifyNewMedia':
          notifier.updateChannelSettings(channelId, newMedia: value);
          break;
        case 'notifyMentions':
          notifier.updateChannelSettings(channelId, mentions: value);
          break;
        case 'notifyLive':
          notifier.updateChannelSettings(channelId, live: value);
          break;
        case 'notifyUpdates':
          notifier.updateChannelSettings(channelId, updates: value);
          break;
        default:
          _loggingService.warning('AppController: Unknown channel setting key: $settingKey');
      }
      _loggingService.debug('AppController: Channel $channelId setting $settingKey updated via notifier.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to update setting $settingKey for channel $channelId', e, s);
    }
  }

  /// Updates a global application setting and notifies the background service if necessary.
  Future<void> updateGlobalSetting(String settingKey, dynamic value) async {
    _loggingService.info('AppController: Updating global setting $settingKey to $value');
    try {
      bool shouldNotifyBackground = false;
      String backgroundMessageKey = '';
      dynamic backgroundMessageValue;

      switch (settingKey) {
        case 'notificationGrouping':
          final bool boolValue = value as bool;
          await _settingsService.setNotificationGrouping(boolValue);
          _ref.read(notificationGroupingProvider.notifier).state = boolValue;
          break;
        case 'delayNewMedia':
          final bool boolValue = value as bool;
          await _settingsService.setDelayNewMedia(boolValue);
          _ref.read(delayNewMediaProvider.notifier).state = boolValue;
          break;
        case 'pollFrequency':
          final Duration durationValue = value as Duration;
          await _settingsService.setPollFrequency(durationValue);
          _ref.read(pollFrequencyProvider.notifier).state = durationValue;
          shouldNotifyBackground = true;
          backgroundMessageKey = 'pollFrequency';
          backgroundMessageValue = durationValue.inMinutes;
          break;
        case 'apiKey':
          final String? stringValue = value as String?;
          final String? valueToStore = (stringValue != null && stringValue.isEmpty) ? null : stringValue;
          await _settingsService.setApiKey(valueToStore);
          _ref.read(apiKeyProvider.notifier).state = valueToStore;
          // API key update doesn't require immediate background notification
          // as the Dio interceptor will fetch it on the next request.
          break;
        default:
          _loggingService.warning('AppController: Unknown global setting key: $settingKey');
          return;
      }
      _loggingService.debug('AppController: Global setting $settingKey updated in state and persisted.');

      // Notify background service if a relevant setting changed
      if (shouldNotifyBackground) {
        try {
          final bgService = _ref.read(backgroundServiceProvider);
          final isRunning = await bgService.isRunning();
          if (isRunning) {
            _loggingService.info(
              'AppController: Notifying running background service of setting change: $backgroundMessageKey=$backgroundMessageValue',
            );
            FlutterBackgroundService().invoke('updateSetting', {'key': backgroundMessageKey, 'value': backgroundMessageValue});
          } else {
            _loggingService.info('AppController: Background service not running, setting [$backgroundMessageKey] will be read on next start.');
          }
        } catch (e, s) {
          _loggingService.error('AppController: Error notifying background service of setting change [$backgroundMessageKey].', e, s);
        }
      }
    } catch (e, s) {
      _loggingService.error('AppController: Failed to update global setting $settingKey', e, s);
    }
  }

  /// Applies the current global default notification settings to all subscribed channels.
  Future<void> applyGlobalDefaultsToAllChannels() async {
    _loggingService.info('AppController: Applying global defaults to all channels.');
    try {
      _ref.read(channelListProvider.notifier).applyGlobalSwitches();
      _loggingService.debug('AppController: Global defaults applied via notifier.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to apply global defaults', e, s);
    }
  }
}
