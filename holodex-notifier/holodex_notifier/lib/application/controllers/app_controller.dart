import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
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
      if (settingKey == 'notifyLive' && !value) {
        // If turning Live notifications OFF
        await _cancelScheduledLiveNotificationsForChannel(channelId);
      }

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

      if (settingKey == 'notifyLive' && value) {
        // If turning Live notifications ON
        await _scheduleMissingLiveNotificationsForChannel(channelId);
      }
      // Always refresh the scheduled list UI after potential changes
      // ignore: unused_result
      _ref.refresh(scheduledNotificationsProvider);
      _loggingService.debug('AppController: Refreshed scheduled notifications provider after setting update.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to update setting $settingKey for channel $channelId', e, s);
    }
  }

  // --- Helper: Cancel Scheduled Live Notifications ---
  Future<void> _cancelScheduledLiveNotificationsForChannel(String channelId) async {
    _loggingService.info('AppController: Cancelling Existing Live schedules for channel $channelId.');
    try {
      // Get all currently scheduled videos (regardless of channel initially)
      // Filtering is done manually after getting the list
      final allScheduled = await _cacheService.getScheduledVideos();
      final channelScheduledToCancel = allScheduled.where((v) => v.channelId == channelId && v.scheduledLiveNotificationId != null).toList();

      if (channelScheduledToCancel.isEmpty) {
        _loggingService.debug('AppController: No active live schedules found for channel $channelId to cancel.');
        return;
      }

      _loggingService.info('AppController: Found ${channelScheduledToCancel.length} live schedules to cancel for channel $channelId.');
      for (final video in channelScheduledToCancel) {
        final notificationId = video.scheduledLiveNotificationId!; // Assert non-null based on query logic
        _loggingService.debug('AppController: Cancelling notification ID $notificationId for video ${video.videoId}');
        try {
          await _notificationService.cancelScheduledNotification(notificationId);
          // Update cache entry ONLY AFTER successful cancellation
          await _cacheService.updateScheduledNotificationId(video.videoId, null);
          _loggingService.debug('AppController: Successfully cancelled and updated cache for video ${video.videoId}.');
        } catch (e, s) {
          _loggingService.error('AppController: Error cancelling notification ID $notificationId or updating cache for video ${video.videoId}', e, s);
          // Decide if we should attempt to proceed with others? Yes.
        }
      }
      _loggingService.info('AppController: Finished cancelling live schedules for channel $channelId.');
    } catch (e, s) {
      _loggingService.error('AppController: Error fetching or processing scheduled videos for cancellation ($channelId).', e, s);
    }
  }

  // --- Helper: Schedule Missing Live Notifications ---
  Future<void> _scheduleMissingLiveNotificationsForChannel(String channelId) async {
    _loggingService.info('AppController: Checking for missing Live schedules for channel $channelId.');
    try {
      // Get all upcoming videos for this specific channel from the cache
      // This needs a new method in CacheService/Database to get *all* videos for a channel
      // For now, let's filter manually after getting all videos (less efficient)
      // TODO: Improve efficiency by adding CacheService.getUpcomingVideosByChannel(channelId)
      final allCachedVideos = await _cacheService.getVideosByStatus('upcoming'); // Approximation, might miss 'new'
      final channelUpcomingVideos = allCachedVideos.where((v) => v.channelId == channelId).toList();

      if (channelUpcomingVideos.isEmpty) {
        _loggingService.debug('AppController: No upcoming videos found in cache for channel $channelId to potentially schedule.');
        return;
      }

      int scheduledCount = 0;
      for (final video in channelUpcomingVideos) {
        // Check if it SHOULD be scheduled now, but ISN'T
        if (video.startScheduled != null && video.scheduledLiveNotificationId == null) {
          final scheduledTime = DateTime.tryParse(video.startScheduled!);
          if (scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
            // Ensure it's in the future
            _loggingService.debug('AppController: Scheduling missing live notification for video ${video.videoId}');
            try {
              final newId = await _notificationService.scheduleNotification(
                videoId: video.videoId,
                scheduledTime: scheduledTime,
                payload: video.videoId,
                title: video.videoTitle,
                channelName: video.channelName,
              );
              if (newId != null) {
                await _cacheService.updateScheduledNotificationId(video.videoId, newId);
                _loggingService.debug('AppController: Successfully scheduled ${video.videoId} with ID $newId.');
                scheduledCount++;
              } else {
                _loggingService.warning('AppController: scheduleNotification returned null ID for ${video.videoId}');
              }
            } catch (e, s) {
              _loggingService.error('AppController: Error scheduling notification for ${video.videoId}', e, s);
              // Continue attempting others
            }
          } else {
            _loggingService.debug('AppController: Skipping ${video.videoId}: Scheduled time is null, invalid, or in the past.');
          }
        } else {
          // Already scheduled or no schedule time - skip
          _loggingService.debug(
            'AppController: Skipping ${video.videoId}: Already scheduled (ID: ${video.scheduledLiveNotificationId}) or no startScheduled.',
          );
        }
      }
      _loggingService.info(
        'AppController: Finished checking for missing live schedules for $channelId. Scheduled $scheduledCount new notifications.',
      );
    } catch (e, s) {
      _loggingService.error('AppController: Error fetching or processing cached videos for scheduling ($channelId).', e, s);
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
          await _ref.read(apiKeyProvider.notifier).updateApiKey(stringValue);
          _loggingService.debug("AppController: updateApiKey called on ApiKeyNotifier.");
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
