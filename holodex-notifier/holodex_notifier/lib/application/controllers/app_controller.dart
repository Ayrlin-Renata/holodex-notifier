import 'dart:convert';
import 'dart:io'; // For File access

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart'; // {{ Import file_picker }}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/models/app_config.dart'; // {{ Import AppConfig }}
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart'; // {{ Import path_provider }}
import 'package:share_plus/share_plus.dart'; // {{ Import share_plus }}
import 'package:path/path.dart' as p; // Path manipulation

class AppController {
  final Ref _ref;
  final ISettingsService _settingsService;
  final ILoggingService _loggingService;
  // ignore: unused_field
  final ICacheService _cacheService;
  final INotificationService _notificationService;
  final INotificationDecisionService _decisionService;
  final INotificationActionHandler _actionHandler;

  // Updated constructor
  AppController(this._ref, this._settingsService, this._loggingService, this._cacheService, this._notificationService, this._decisionService,
    this._actionHandler,
  );

  /// Adds a channel based on search result data.
  Future<void> addChannel(Channel channelData) async {
    _loggingService.info('AppController: Adding channel ${channelData.id}: ${channelData.name}');
    try {
      // Read default settings from providers
      final globalNew = _ref.read(globalNewMediaDefaultProvider);
      final globalMention = _ref.read(globalMentionsDefaultProvider);
      final globalLive = _ref.read(globalLiveDefaultProvider);
      final globalUpdate = _ref.read(globalUpdateDefaultProvider);
      final globalMembers = _ref.read(globalMembersOnlyDefaultProvider);
      final globalClips = _ref.read(globalClipsDefaultProvider);

      final newSetting = ChannelSubscriptionSetting(
        channelId: channelData.id,
        name: channelData.name,
        avatarUrl: channelData.photo,
        notifyNewMedia: globalNew,
        notifyMentions: globalMention,
        notifyLive: globalLive,
        notifyUpdates: globalUpdate,
        notifyMembersOnly: globalMembers, // Set new defaults
        notifyClips: globalClips, // Set new defaults
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
      // --- Refactored Cleanup Logic ---
      final actions = await _decisionService.determineActionsForChannelRemoval(channelId: channelId);
      _loggingService.debug('AppController: Decision service determined ${actions.length} actions for removal.');
      await _actionHandler.executeActions(actions);
      _loggingService.info('AppController: Action handler executed cleanup actions for channel $channelId.');
      // --- End Refactored Cleanup Logic ---

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
  Future<void> updateChannelNotificationSetting(String channelId, String settingKey, bool newValue) async {
    _loggingService.info('AppController: Updating $settingKey for channel $channelId to $newValue');
    try {
      // --- Get Old Value (Needed for Decision Service) ---
      final oldChannelSetting = _ref.read(channelListProvider).firstWhereOrNull((s) => s.channelId == channelId);
      if (oldChannelSetting == null) {
        _loggingService.error("AppController: Cannot update setting $settingKey, channel $channelId not found in current state.");
        return;
      }
      // Determine the old value based on settingKey
      bool oldValue;
      switch (settingKey) {
        case 'notifyNewMedia':
          oldValue = oldChannelSetting.notifyNewMedia;
          break;
        case 'notifyMentions':
          oldValue = oldChannelSetting.notifyMentions;
          break;
        case 'notifyLive':
          oldValue = oldChannelSetting.notifyLive;
          break;
        case 'notifyUpdates':
          oldValue = oldChannelSetting.notifyUpdates;
          break;
        case 'notifyMembersOnly':
          oldValue = oldChannelSetting.notifyMembersOnly;
          break;
        case 'notifyClips':
          oldValue = oldChannelSetting.notifyClips;
          break;
        default:
          _loggingService.warning('AppController: Unknown channel setting key: $settingKey');
          return;
      }

      // --- Call Decision Service BEFORE updating state provider ---
      final actions = await _decisionService.determineActionsForChannelSettingChange(
        channelId: channelId,
        settingKey: settingKey,
        oldValue: oldValue,
        newValue: newValue,
      );
      _loggingService.debug('AppController: Decision service determined ${actions.length} actions for setting change.');

      // --- Update State Provider ---
      final notifier = _ref.read(channelListProvider.notifier);
      switch (settingKey) {
        case 'notifyNewMedia':
          notifier.updateChannelSettings(channelId, newMedia: newValue);
          break;
        case 'notifyMentions':
          notifier.updateChannelSettings(channelId, mentions: newValue);
          break;
        case 'notifyLive':
          notifier.updateChannelSettings(channelId, live: newValue);
          break;
        case 'notifyUpdates':
          notifier.updateChannelSettings(channelId, updates: newValue);
          break;
        case 'notifyMembersOnly':
          notifier.updateChannelSettings(channelId, membersOnly: newValue);
          break;
        case 'notifyClips':
          notifier.updateChannelSettings(channelId, clips: newValue);
          break;
        // Default handled above
      }
      _loggingService.debug('AppController: Channel $channelId setting $settingKey updated via notifier.');

      // --- Execute Actions ---
      await _actionHandler.executeActions(actions);
      _loggingService.info('AppController: Action handler executed actions for setting change.');

      // Always refresh the scheduled list UI after potential changes
      // ignore: unused_result
      _ref.refresh(scheduledNotificationsProvider);
      _loggingService.debug('AppController: Refreshed scheduled notifications provider after setting update.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to update setting $settingKey for channel $channelId', e, s);
    }
  }

  /// Updates a global application setting and notifies the background service if necessary.
  Future<void> updateGlobalSetting(String settingKey, dynamic value) async {
    // ... (Logging remains the same) ...
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

      // Needed for reminder lead time change
      Duration? oldReminderLeadTime;

      // --- Update Riverpod State (Immediate) ---
      try {
        switch (settingKey) {
          case 'notificationGrouping':
            _ref.read(notificationGroupingProvider.notifier).update((_) => value as bool);
            break;
          case 'delayNewMedia':
            _ref.read(delayNewMediaProvider.notifier).update((_) => value as bool);
            break;
          case 'pollFrequency':
            _ref.read(pollFrequencyProvider.notifier).update((_) => value as Duration);
            break;
          case 'reminderLeadTime':
            oldReminderLeadTime = _ref.read(reminderLeadTimeProvider); // Read *before* updating
            _ref.read(reminderLeadTimeProvider.notifier).update((_) => value as Duration);
            break;
          case 'apiKey':
            break; // Handled by ApiKeyNotifier below
          default:
            _loggingService.warning('AppController: Unknown global setting key for state update: $settingKey');
            return;
        }
        _loggingService.debug('AppController: Riverpod state updated immediately for $settingKey.');
      } catch (stateError) {
        _loggingService.error('AppController: Error updating Riverpod state for $settingKey', stateError);
      }

      // --- Perform Persistence and Side Effects (async) ---
      List<NotificationAction> actions = []; // Collect actions for setting change
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
          // Get actions from decision service instead of calling old helper
          if (oldReminderLeadTime != null) {
            actions = await _decisionService.determineActionsForReminderLeadTimeChange(oldLeadTime: oldReminderLeadTime, newLeadTime: durationValue);
            _loggingService.debug('AppController: Decision service determined ${actions.length} actions for reminder lead time change.');
          }
          // Don't notify background directly here? The action handler will deal with it.
          // shouldNotifyBackground = true; // This seems specific to poller interval
          // backgroundMessageKey = 'reminderLeadTime';
          // backgroundMessageValue = durationValue.inMinutes;
          break;
        case 'apiKey':
          await _ref.read(apiKeyProvider.notifier).updateApiKey(value as String?);
          _loggingService.debug("AppController: updateApiKey called on ApiKeyNotifier for persistence.");
          break;
        // Default case already handled above
      }
      _loggingService.debug('AppController: Global setting $settingKey persisted.');

      // --- Execute Actions (e.g., for reminder change) ---
      if (actions.isNotEmpty) {
        await _actionHandler.executeActions(actions);
        _loggingService.info('AppController: Action handler executed ${actions.length} actions for global setting change.');
        // Refresh UI after actions
        // ignore: unused_result
        _ref.refresh(scheduledNotificationsProvider);
      }

      // --- Notify Background (if needed) ---
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
      // --- Get Old Settings ---
      final List<ChannelSubscriptionSetting> oldSettings = List.from(_ref.read(channelListProvider));

      // --- Apply global defaults via notifier (Updates state provider) ---
      _ref.read(channelListProvider.notifier).applyGlobalSwitches();
      _loggingService.debug('AppController: Global defaults applied via notifier.');

      // --- Get New Settings ---
      final List<ChannelSubscriptionSetting> newSettings = _ref.read(channelListProvider);

      // --- Call Decision Service ---
      final actions = await _decisionService.determineActionsForApplyGlobalDefaults(oldSettings: oldSettings, newSettings: newSettings);
      _loggingService.debug('AppController: Decision service determined ${actions.length} actions for applying global defaults.');

      // --- Execute Actions ---
      await _actionHandler.executeActions(actions);
      _loggingService.info('AppController: Action handler executed actions for applying global defaults.');

      // --- Refresh UI ---
      // ignore: unused_result
      _ref.refresh(scheduledNotificationsProvider);
      _loggingService.debug('AppController: Refreshed scheduled notifications provider after applying global defaults.');
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
      DateTime exampleTime = now;
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
          exampleTime = now.add(const Duration(minutes: 1)).toLocal(); // Time 1 min from now
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
        availableAt: exampleTime, 
      );

      // Special handling for reminder test formatting placeholders
      if (type == NotificationEventType.reminder) {
        // For the test, we need to simulate formatting that expects a scheduledTime
        // We can manually replace placeholders here for the test body.
        instruction.copyWith(videoTitle: testVideoTitle.replaceAll('{relativeTime}', exampleRelTime));
        // Note: The title template might also use {relativeTime} or {mediaTime}
        // which won't be perfectly replaced by the service formatter for an immediate
        // call, but this tests the body at least. A full test would involve scheduling.
      }

      // Add the dispatch call to a list of futures
      dispatchFutures.add(
        // ignore: body_might_complete_normally_catch_error
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
