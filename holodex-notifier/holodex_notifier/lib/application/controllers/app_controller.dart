import 'dart:convert';
import 'dart:io'; // For File access

import 'package:file_picker/file_picker.dart'; // {{ Import file_picker }}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/models/app_config.dart'; // {{ Import AppConfig }}
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/infrastructure/services/drift_cache_service.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; // {{ Import path_provider }}
import 'package:share_plus/share_plus.dart'; // {{ Import share_plus }}
import 'package:path/path.dart' as p; // Path manipulation

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
        await _cancelScheduledRemindersAndLiveForChannel(channelId);
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
        await _scheduleMissingRemindersAndLiveForChannel(channelId);
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
  Future<void> _cancelScheduledRemindersAndLiveForChannel(String channelId) async {
    _loggingService.info('AppController: Cancelling Existing Live & Reminder schedules for channel $channelId.');
    try {
      // Get all currently scheduled LIVE videos for the channel
      // Note: getScheduledVideos only returns LIVE scheduled ones currently.
      // TODO: Maybe filter all cached videos for the channel first?
      final allScheduledLive = await _cacheService.getScheduledVideos();
      final channelScheduledLiveToCancel = allScheduledLive.where((v) => v.channelId == channelId && v.scheduledLiveNotificationId != null).toList();

      // {{ Get all currently scheduled REMINDER videos for the channel }}
      // Assume DriftCacheService has getVideosWithScheduledReminders() -> database.getVideosWithScheduledRemindersInternal()
      // Cast is safe IF the interface/impl matches. Add try-catch just in case.
      List<CachedVideo> channelScheduledRemindersToCancel = [];
      try {
        if (_cacheService is DriftCacheService) {
          final allReminders = await (_cacheService).getVideosWithScheduledReminders();
          channelScheduledRemindersToCancel =
              allReminders.where((v) => v.channelId == channelId && v.scheduledReminderNotificationId != null).toList();
        } else {
          _loggingService.warning("AppController: CacheService is not DriftCacheService, cannot fetch reminders directly.");
        }
      } catch (e, s) {
        _loggingService.error("AppController: Error fetching reminders for channel $channelId.", e, s);
      }

      final totalToCancel = channelScheduledLiveToCancel.length + channelScheduledRemindersToCancel.length;
      if (totalToCancel == 0) {
        _loggingService.debug('AppController: No active live or reminder schedules found for channel $channelId to cancel.');
        return;
      }

      _loggingService.info(
        'AppController: Found $totalToCancel schedules (Live: ${channelScheduledLiveToCancel.length}, Reminder: ${channelScheduledRemindersToCancel.length}) to cancel for channel $channelId.',
      );

      // Cancel Live Notifications
      for (final video in channelScheduledLiveToCancel) {
        final notificationId = video.scheduledLiveNotificationId!; // Assert non-null based on query logic
        _loggingService.debug('AppController: Cancelling LIVE notification ID $notificationId for video ${video.videoId}');
        try {
          await _notificationService.cancelScheduledNotification(notificationId);
          await _cacheService.updateScheduledNotificationId(video.videoId, null);
          _loggingService.debug('AppController: Successfully cancelled LIVE and updated cache for video ${video.videoId}.');
        } catch (e, s) {
          _loggingService.error(
            'AppController: Error cancelling LIVE notification ID $notificationId or updating cache for video ${video.videoId}',
            e,
            s,
          );
        }
      }

      // {{ Cancel Reminder Notifications }}
      for (final video in channelScheduledRemindersToCancel) {
        final notificationId = video.scheduledReminderNotificationId!;
        _loggingService.debug('AppController: Cancelling REMINDER notification ID $notificationId for video ${video.videoId}');
        try {
          await _notificationService.cancelScheduledNotification(notificationId);
          // Update cache entry ONLY AFTER successful cancellation - needs specific method
          // Assume DriftCacheService has `updateScheduledReminderNotificationId`
          if (_cacheService is DriftCacheService) {
            await (_cacheService).updateScheduledReminderNotificationId(video.videoId, null);
            // Also clear the reminder time? Yes. Needs `updateScheduledReminderTime`
            await (_cacheService).updateScheduledReminderTime(video.videoId, null);
            _loggingService.debug('AppController: Successfully cancelled REMINDER and updated cache for video ${video.videoId}.');
          } else {
            _loggingService.warning("AppController: Cannot update reminder cache for ${video.videoId}, CacheService not DriftCacheService.");
          }
        } catch (e, s) {
          _loggingService.error(
            'AppController: Error cancelling REMINDER notification ID $notificationId or updating cache for video ${video.videoId}',
            e,
            s,
          );
        }
      }

      _loggingService.info('AppController: Finished cancelling schedules for channel $channelId.');
    } catch (e, s) {
      _loggingService.error('AppController: Error fetching or processing scheduled videos for cancellation ($channelId).', e, s);
    }
  }

  // --- Helper: Schedule Missing Notifications (Live AND Reminder) ---
  // {{ --- Rename and update helper to schedule BOTH --- }}
  Future<void> _scheduleMissingRemindersAndLiveForChannel(String channelId) async {
    _loggingService.info('AppController: Checking for missing Live & Reminder schedules for channel $channelId.');
    try {
      // Get reminder lead time setting first
      final reminderLeadTime = await _settingsService.getReminderLeadTime();
      _loggingService.debug('AppController: Reminder lead time is ${reminderLeadTime.inMinutes} minutes.');

      // Get all upcoming/new videos for this specific channel from the cache
      // TODO: Improve efficiency with CacheService method
      final allCachedVideos = await _cacheService.getVideosByStatus('upcoming') + await _cacheService.getVideosByStatus('new'); // Get both
      final channelRelevantVideos = allCachedVideos.where((v) => v.channelId == channelId).toList();

      if (channelRelevantVideos.isEmpty) {
        _loggingService.debug('AppController: No upcoming/new videos found in cache for channel $channelId to potentially schedule.');
        return;
      }

      int scheduledLiveCount = 0;
      int scheduledReminderCount = 0;

      for (final video in channelRelevantVideos) {
        final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
        if (scheduledTime == null || scheduledTime.isBefore(DateTime.now())) {
          _loggingService.debug('AppController: Skipping ${video.videoId}: Scheduled time is null, invalid, or in the past ($scheduledTime).');
          continue; // Skip if no valid future schedule time
        }

        // Schedule Live Notification if missing
        if (video.scheduledLiveNotificationId == null) {
          _loggingService.debug('AppController: Attempting to schedule missing LIVE notification for video ${video.videoId}');
          try {
            // Create instruction
            final instruction = NotificationInstruction(
              videoId: video.videoId,
              eventType: NotificationEventType.live,
              channelId: video.channelId,
              channelName: video.channelName,
              videoTitle: video.videoTitle,
              channelAvatarUrl: video.channelAvatarUrl,
              availableAt: DateTime.parse(video.availableAt),
            );
            // Call with new signature
            final newId = await _notificationService.scheduleNotification(
              instruction: instruction,
              scheduledTime: scheduledTime, // Live notification at scheduled time
            );
            if (newId != null) {
              await _cacheService.updateScheduledNotificationId(video.videoId, newId);
              scheduledLiveCount++;
            } else {
              _loggingService.warning('AppController: scheduleNotification (Live) returned null ID for ${video.videoId}');
            }
          } catch (e, s) {
            _loggingService.error('AppController: Error scheduling LIVE notification for ${video.videoId}', e, s);
          }
        } else {
          _loggingService.debug(
            'AppController: Skipping LIVE scheduling for ${video.videoId}: Already scheduled (ID: ${video.scheduledLiveNotificationId}).',
          );
        }

        // {{ Schedule Reminder Notification if applicable and missing }}
        if (reminderLeadTime > Duration.zero) {
          // Check if reminder setting is enabled
          final calculatedReminderTime = scheduledTime.subtract(reminderLeadTime);
          // Check if reminder time is in the future AND reminder is not already scheduled
          // AND reminder time is significantly different from existing (if exists)
          final bool needsReminderSchedule = calculatedReminderTime.isAfter(DateTime.now()) && video.scheduledReminderNotificationId == null;
          // Add check for time difference if complex rescheduling needed

          if (needsReminderSchedule) {
            _loggingService.debug(
              'AppController: Attempting to schedule missing REMINDER notification for video ${video.videoId} at $calculatedReminderTime',
            );
            try {
              // Create instruction
              final instruction = NotificationInstruction(
                videoId: video.videoId,
                eventType: NotificationEventType.reminder,
                channelId: video.channelId,
                channelName: video.channelName,
                videoTitle: video.videoTitle,
                channelAvatarUrl: video.channelAvatarUrl,
                availableAt: DateTime.parse(video.availableAt),
              );
              // Call with new signature
              final newId = await _notificationService.scheduleNotification(
                instruction: instruction,
                scheduledTime: calculatedReminderTime, // Reminder notification at calculated time
              );
              if (newId != null) {
                // Assume DriftCacheService has these methods
                if (_cacheService is DriftCacheService) {
                  await (_cacheService).updateScheduledReminderNotificationId(video.videoId, newId);
                  await (_cacheService).updateScheduledReminderTime(video.videoId, calculatedReminderTime);
                  scheduledReminderCount++;
                } else {
                  _loggingService.warning("AppController: Cannot update reminder cache post-schedule, CacheService not DriftCacheService.");
                }
              } else {
                _loggingService.warning('AppController: scheduleNotification (Reminder) returned null ID for ${video.videoId}');
              }
            } catch (e, s) {
              _loggingService.error('AppController: Error scheduling REMINDER notification for ${video.videoId}', e, s);
            }
          } else if (video.scheduledReminderNotificationId != null) {
            _loggingService.debug(
              'AppController: Skipping REMINDER scheduling for ${video.videoId}: Already scheduled (ID: ${video.scheduledReminderNotificationId}).',
            );
          } else if (!calculatedReminderTime.isAfter(DateTime.now())) {
            _loggingService.debug(
              'AppController: Skipping REMINDER scheduling for ${video.videoId}: Calculated reminder time ($calculatedReminderTime) is in the past.',
            );
          }
        } else {
          _loggingService.debug('AppController: Skipping REMINDER scheduling for ${video.videoId}: Reminder setting disabled (LeadTime 0).');
          // Optionally, cancel existing reminder if setting is now disabled
          if (video.scheduledReminderNotificationId != null) {
            _loggingService.info('AppController: Cancelling existing REMINDER for ${video.videoId} as setting is now disabled.');
            await _notificationService.cancelScheduledNotification(video.scheduledReminderNotificationId!);
            if (_cacheService is DriftCacheService) {
              await (_cacheService).updateScheduledReminderNotificationId(video.videoId, null);
              await (_cacheService).updateScheduledReminderTime(video.videoId, null);
            }
          }
        }
      }
      _loggingService.info(
        'AppController: Finished checking for missing schedules for $channelId. Scheduled $scheduledLiveCount new Live and $scheduledReminderCount new Reminder notifications.',
      );
    } catch (e, s) {
      _loggingService.error('AppController: Error fetching or processing cached videos for scheduling ($channelId).', e, s);
    }
  }

  /// Updates a global application setting and notifies the background service if necessary.
  Future<void> updateGlobalSetting(String settingKey, dynamic value) async {
    if (settingKey == "apiKey") {
      _loggingService.debug('AppController: Updating global setting $settingKey to $value');
      _loggingService.info('AppController: Updating global setting $settingKey to [redacted-for-info-level]');
    } else {
      _loggingService.info('AppController: Updating global setting $settingKey to $value');
    }
    try {
      bool shouldNotifyBackground = false;
      String backgroundMessageKey = '';
      dynamic backgroundMessageValue;

      try {
        switch (settingKey) {
          case 'notificationGrouping':
            // {{ Use .update() method for state change }}
            _ref.read(notificationGroupingProvider.notifier).update((_) => value as bool);
            break;
          case 'delayNewMedia':
            // {{ Use .update() method for state change }}
            _ref.read(delayNewMediaProvider.notifier).update((_) => value as bool);
            break;
          case 'pollFrequency':
            // {{ Use .update() method for state change }}
            _ref.read(pollFrequencyProvider.notifier).update((_) => value as Duration);
            break;
          case 'reminderLeadTime':
            // {{ Use .update() method for state change }}
            _ref.read(reminderLeadTimeProvider.notifier).update((_) => value as Duration);
            break;
          case 'apiKey':
            // ApiKeyNotifier handles its own state update internally upon successful save.
            // We trigger the save later in this method.
            break;
          default:
            _loggingService.warning('AppController: Unknown global setting key for state update: $settingKey');
            // Do not proceed if the key is unknown
            return;
        }
        _loggingService.debug('AppController: Riverpod state updated immediately for $settingKey.');
      } catch (stateError) {
        _loggingService.error('AppController: Error updating Riverpod state for $settingKey', stateError);
        // Optionally rethrow or return if state update fails critically
      }

      // --- Perform Persistence and Side Effects (async) ---
      switch (settingKey) {
        case 'notificationGrouping':
          await _settingsService.setNotificationGrouping(value as bool);
          break;
        case 'delayNewMedia':
          await _settingsService.setDelayNewMedia(value as bool);
          break;
        case 'pollFrequency':
          final Duration durationValue = value as Duration;
          await _settingsService.setPollFrequency(durationValue);
          shouldNotifyBackground = true;
          backgroundMessageKey = 'pollFrequency';
          backgroundMessageValue = durationValue.inMinutes;
          break;
        case 'reminderLeadTime':
          final Duration durationValue = value as Duration;
          await _settingsService.setReminderLeadTime(durationValue);
          await _scheduleOrCancelRemindersForAllChannels(); // Keep this side effect with persistence
          shouldNotifyBackground = true;
          backgroundMessageKey = 'reminderLeadTime';
          backgroundMessageValue = durationValue.inMinutes;
          break;
        case 'apiKey':
          // Trigger the save action in the ApiKeyNotifier
          await _ref.read(apiKeyProvider.notifier).updateApiKey(value as String?);
          _loggingService.debug("AppController: updateApiKey called on ApiKeyNotifier for persistence.");
          break;
        // Default case already handled above
      }
      _loggingService.debug('AppController: Global setting $settingKey persisted.'); // Log persistence completion

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

  Future<void> _scheduleOrCancelRemindersForAllChannels() async {
    _loggingService.info("AppController: Re-evaluating reminders for all channels due to lead time change...");
    final channels = _ref.read(channelListProvider); // Get current channel subscriptions
    for (final channelSetting in channels) {
      // Only process channels where Live notifications are enabled
      if (channelSetting.notifyLive) {
        _loggingService.debug("AppController: Re-evaluating reminders for channel ${channelSetting.channelId}");
        // Combine the logic from enable/disable helpers for this specific channel
        await _cancelScheduledRemindersAndLiveForChannel(channelSetting.channelId); // Cancel existing first (safer)
        await _scheduleMissingRemindersAndLiveForChannel(channelSetting.channelId); // Reschedule based on new setting
      }
    }
    _loggingService.info("AppController: Finished re-evaluating reminders for all channels.");
    // ignore: unused_result
    _ref.refresh(scheduledNotificationsProvider); // Refresh UI list
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

  // --- Export Configuration ---
  Future<bool> exportConfiguration() async {
    _loggingService.info('AppController: Exporting configuration...');
    try {
      // 1. Get config data from SettingsService
      final AppConfig configData = await _settingsService.exportConfiguration();
      // 2. Serialize to JSON
      final String configJson = jsonEncode(configData.toJson());
      // 3. Write to a temporary file
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, 'holodex_notifier_config.json');
      final file = File(filePath);
      await file.writeAsString(configJson);
      _loggingService.debug('AppController: Config saved to temporary file: $filePath');

      // 4. Share the file
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Holodex Notifier Configuration',
        subject: 'HolodexNotifier_Config', // Subject for email sharing
      );

      // 5. Clean up temp file (optional, temp dir is usually cleared by OS)
      // await file.delete();

      if (result.status == ShareResultStatus.success) {
        _loggingService.info('AppController: Configuration exported and shared successfully.');
        return true;
      } else {
        _loggingService.warning('AppController: Configuration export sharing status: ${result.status}');
        return false; // Indicate sharing wasn't explicitly successful
      }
    } catch (e, s) {
      _loggingService.error('AppController: Failed to export configuration', e, s);
      return false;
    }
  }

  // --- Import Configuration ---
  Future<bool> importConfiguration() async {
    _loggingService.info('AppController: Starting configuration import...');
    try {
      // 1. Pick file using file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'], // Allow only JSON files
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        _loggingService.debug('AppController: File picked for import: $filePath');
        final file = File(filePath);
        // 2. Read file content
        final String fileContent = await file.readAsString();
        // 3. Deserialize JSON
        final Map<String, dynamic> jsonMap = jsonDecode(fileContent);
        final AppConfig importedConfig = AppConfig.fromJson(jsonMap);
        _loggingService.debug('AppController: Configuration JSON parsed successfully.');

        // 4. Apply configuration via SettingsService
        final bool success = await _settingsService.importConfiguration(importedConfig);

        if (success) {
          _loggingService.info('AppController: Configuration imported and applied successfully.');
          // 5. Refresh relevant providers
          await _refreshStateAfterImport();
          _loggingService.debug('AppController: UI State refreshed after import.');
          return true;
        } else {
          _loggingService.error('AppController: SettingsService reported failure during import application.');
          return false;
        }
      } else {
        // User canceled the picker
        _loggingService.info('AppController: File import canceled by user.');
        return false; // Indicate cancellation, not error
      }
    } catch (e, s) {
      _loggingService.error('AppController: Failed to import configuration', e, s);
      return false;
    }
  }

  // Helper to refresh providers after import
  Future<void> _refreshStateAfterImport() async {
    // Reload channel list directly from storage via its notifier
    await _ref.read(channelListProvider.notifier).reloadState();

    // Refetch individual settings for StateProviders
    final newFreq = await _settingsService.getPollFrequency();
    final newGroup = await _settingsService.getNotificationGrouping();
    final newDelay = await _settingsService.getDelayNewMedia();
    final newReminderLead = await _settingsService.getReminderLeadTime();
    _ref.read(pollFrequencyProvider.notifier).state = newFreq;
    _ref.read(notificationGroupingProvider.notifier).state = newGroup;
    _ref.read(delayNewMediaProvider.notifier).state = newDelay;
    _ref.read(reminderLeadTimeProvider.notifier).state = newReminderLead;

    // Refresh API Key notifier (although it shouldn't change on import)
    // ignore: unused_result
    _ref.refresh(apiKeyProvider);

    // Notify background service of potential poll frequency change
    await updateGlobalSetting('pollFrequency', newFreq);
    await updateGlobalSetting('reminderLeadTime', newReminderLead);
  }

    Future<void> sendTestNotifications() async {
    _loggingService.info("AppController: Sending test notifications...");
    final DateTime now = DateTime.now();
    const String testChannelId = 'UCtestChannel';
    const String testChannelName = 'Test Channel';
    const String testAvatarUrl =
        'https://yt3.googleusercontent.com/ytc/AIdro_nb5QnwxQzM8drdXb1WgsHr6O5O5w7zF9Gf9w=s176-c-k-c0x00ffffff-no-rj'; // Example URL

    final List<Future<void>> dispatchFutures = [];

    for (final type in NotificationEventType.values) {
      // Use unique IDs for testing to avoid potential conflicts if video IDs were reused
      final testVideoId = 'test-${type.name}-${now.millisecondsSinceEpoch}';
      String testVideoTitle;
      String? testVideoType;
      String exampleTime = DateFormat.jm().format(now.toLocal());
      String exampleDate = DateFormat('yyyy-MM-dd').format(now.toLocal());
      String exampleRelTime = 'in 1 min';

      switch (type) {
        case NotificationEventType.newMedia:
          testVideoTitle = 'This is a test New Media body. Relative: {relativeTime}';
          testVideoType = 'stream';
          break;
        case NotificationEventType.mention:
          testVideoTitle = 'This is a test Mention body. YMD: {mediaDateYMD}';
          testVideoType = 'clip';
          break;
        case NotificationEventType.live:
          testVideoTitle = 'This is a test LIVE notification body. Time: {mediaTime}';
          testVideoType = 'stream';
          break;
        case NotificationEventType.reminder:
          testVideoTitle = 'This is a test Reminder body. Date: {mediaDateAsia}';
          testVideoType = 'video';
          // For reminder test, pass a future time to simulate 'in X'
          exampleTime = DateFormat.jm().format(now.add(const Duration(minutes: 1)).toLocal()); // Time 1 min from now
          exampleRelTime = 'in 1 min'; // Hardcode relative for test
          break;
        case NotificationEventType.update:
          testVideoTitle = 'This is a test Update body. MDY: {mediaDateMDY}';
          testVideoType = 'placeholder';
          break;
      }

      final instruction = NotificationInstruction(
        videoId: testVideoId,
        eventType: type,
        channelId: testChannelId,
        channelName: testChannelName,
        videoTitle: testVideoTitle,
        videoType: testVideoType,
        channelAvatarUrl: testAvatarUrl,
        availableAt: now, // Use current time for availableAt
      );

      // Special handling for reminder test formatting placeholders
      if (type == NotificationEventType.reminder) {
        // For the test, we need to simulate formatting that expects a scheduledTime
        // We can manually replace placeholders here for the test body.
        instruction.copyWith(
          videoTitle: testVideoTitle.replaceAll('{relativeTime}', exampleRelTime),
        );
        // Note: The title template might also use {relativeTime} or {mediaTime}
        // which won't be perfectly replaced by the service formatter for an immediate
        // call, but this tests the body at least. A full test would involve scheduling.
      }

      // Add the dispatch call to a list of futures
      dispatchFutures.add(
        _notificationService.showNotification(instruction).catchError((e, s) {
          _loggingService.error("Error sending test notification type $type", e, s);
          // Don't rethrow, try sending others
        }),
      );
    }

    // Wait for all dispatch calls to attempt completion
    await Future.wait(dispatchFutures);
    _loggingService.info("AppController: Test notification dispatch attempted for all types.");
  }
}
