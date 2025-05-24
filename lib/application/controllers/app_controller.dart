// ignore_for_file: unused_result, body_might_complete_normally_catch_error

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/app_config.dart';
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppController {
  final Ref _ref;
  final ISettingsService _settingsService;
  final ILoggingService _loggingService;
  // ignore: unused_field
  final ICacheService _cacheService;
  final INotificationService _notificationService;
  final INotificationDecisionService _decisionService;
  final INotificationActionHandler _actionHandler;

  AppController(
    this._ref,
    this._settingsService,
    this._loggingService,
    this._cacheService,
    this._notificationService,
    this._decisionService,
    this._actionHandler,
  );

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    _loggingService.info('AppController: Handling FCM foreground message.');
    try {
      final String? videoJsonString = message.data['video'];

      if (videoJsonString != null) {
        final Map<String, dynamic> parsedJson = jsonDecode(videoJsonString);
        final VideoFull videoFullFromFcm = VideoFull.fromJson(parsedJson);
        _loggingService.info('AppController: Successfully parsed VideoFull for foreground handling.');

        CachedVideo? cachedVideo;
        try {
          cachedVideo = await _cacheService.getVideo(videoFullFromFcm.id);
          _loggingService.debug('AppController: CachedVideo fetched: ${cachedVideo != null}');
        } catch (cacheError, cacheStack) {
          _loggingService.warning('AppController: Error fetching cached video.', cacheError, cacheStack);
        }

        final List<ChannelSubscriptionSetting> allChannelSettings = await _settingsService.getChannelSubscriptions();
        final Set<String> mentionedForChannels = videoFullFromFcm.mentions?.map((m) => m.id).toSet() ?? {};

        final actions = await _decisionService.determineActionsForVideoUpdate(
          fetchedVideo: videoFullFromFcm,
          cachedVideo: cachedVideo,
          allChannelSettings: allChannelSettings,
          mentionedForChannels: mentionedForChannels,
        );
        _loggingService.info('AppController: determined ${actions.length} actions for foreground message.');

        await _actionHandler.executeActions(actions);
        _loggingService.info('AppController: Executed actions for foreground message.');
      } else {
        _loggingService.error('AppController: No valid JSON payload found in FCM data for foreground message.');
      }
    } catch (e, s) {
      _loggingService.error('AppController: Error handling FCM foreground message.', e, s);
    }
  }

  Future<void> addChannel(Channel channelData) async {
    _loggingService.info('AppController: Adding channel ${channelData.id}: ${channelData.name}');
    try {
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
        notifyMembersOnly: globalMembers,
        notifyClips: globalClips,
      );

      _ref.read(channelListProvider.notifier).addChannel(newSetting);
      _loggingService.debug('AppController: Channel ${channelData.id} added to state.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to add channel ${channelData.id}', e, s);
    }
  }

  Future<void> removeChannel(String channelId) async {
    _loggingService.info('AppController: Removing channel $channelId and cleaning up scheduled notifications.');
    try {
      final actions = await _decisionService.determineActionsForChannelRemoval(channelId: channelId);
      _loggingService.debug('AppController: Decision service determined ${actions.length} actions for removal.');
      await _actionHandler.executeActions(actions);
      _loggingService.info('AppController: Action handler executed cleanup actions for channel $channelId.');

      _ref.read(channelListProvider.notifier).removeChannel(channelId);
      _loggingService.debug('AppController: Channel $channelId removed from state.');

      _ref.refresh(scheduledNotificationsProvider);
      _loggingService.debug('AppController: Refreshed scheduled notifications provider.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to remove channel $channelId', e, s);
    }
  }

  Future<void> updateChannelNotificationSetting(String channelId, String settingKey, bool newValue) async {
    _loggingService.info('AppController: Updating $settingKey for channel $channelId to $newValue');
    try {
      final oldChannelSetting = _ref.read(channelListProvider).firstWhereOrNull((s) => s.channelId == channelId);
      if (oldChannelSetting == null) {
        _loggingService.error("AppController: Cannot update setting $settingKey, channel $channelId not found in current state.");
        return;
      }
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

      final actions = await _decisionService.determineActionsForChannelSettingChange(
        channelId: channelId,
        settingKey: settingKey,
        oldValue: oldValue,
        newValue: newValue,
      );
      _loggingService.debug('AppController: Decision service determined ${actions.length} actions for setting change.');

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
      }
      _loggingService.debug('AppController: Channel $channelId setting $settingKey updated via notifier.');

      await _actionHandler.executeActions(actions);
      _loggingService.info('AppController: Action handler executed actions for setting change.');

      _ref.refresh(scheduledNotificationsProvider);
      _loggingService.debug('AppController: Refreshed scheduled notifications provider after setting update.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to update setting $settingKey for channel $channelId', e, s);
    }
  }

  Future<void> updateGlobalSetting(String settingKey, dynamic value) async {
    if (settingKey == "apiKey") {
      _loggingService.debug('AppController: Updating global setting $settingKey to $value');
      _loggingService.info('AppController: Updating global setting $settingKey to [redacted-for-info-level]');
    } else {
      _loggingService.info('AppController: Updating global setting $settingKey to $value');
    }
    try {
      Duration? oldReminderLeadTime;

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
            oldReminderLeadTime = _ref.read(reminderLeadTimeProvider);
            _ref.read(reminderLeadTimeProvider.notifier).update((_) => value as Duration);
            break;
          case 'apiKey':
            break;
          default:
            _loggingService.warning('AppController: Unknown global setting key for state update: $settingKey');
            return;
        }
        _loggingService.debug('AppController: Riverpod state updated immediately for $settingKey.');
      } catch (stateError) {
        _loggingService.error('AppController: Error updating Riverpod state for $settingKey', stateError);
      }

      List<NotificationAction> actions = [];
      switch (settingKey) {
        case 'notificationGrouping':
          await _settingsService.setNotificationGrouping(value as bool);
          break;
        case 'delayNewMedia':
          await _settingsService.setDelayNewMedia(value as bool);
          break;
        case 'reminderLeadTime':
          final Duration durationValue = value as Duration;
          await _settingsService.setReminderLeadTime(durationValue);
          if (oldReminderLeadTime != null) {
            actions = await _decisionService.determineActionsForReminderLeadTimeChange(oldLeadTime: oldReminderLeadTime, newLeadTime: durationValue);
            _loggingService.debug('AppController: Decision service determined ${actions.length} actions for reminder lead time change.');
          }
          break;
        case 'apiKey':
          await _ref.read(apiKeyProvider.notifier).updateApiKey(value as String?);
          _loggingService.debug("AppController: updateApiKey called on ApiKeyNotifier for persistence.");
          break;
      }
      _loggingService.debug('AppController: Global setting $settingKey persisted.');

      if (actions.isNotEmpty) {
        await _actionHandler.executeActions(actions);
        _loggingService.info('AppController: Action handler executed ${actions.length} actions for global setting change.');
        _ref.refresh(scheduledNotificationsProvider);
      }
    } catch (e, s) {
      _loggingService.error('AppController: Failed to update global setting $settingKey', e, s);
    }
  }

  Future<void> applyGlobalDefaultsToAllChannels() async {
    _loggingService.info('AppController: Applying global defaults to all channels.');
    try {
      final List<ChannelSubscriptionSetting> oldSettings = List.from(_ref.read(channelListProvider));

      _ref.read(channelListProvider.notifier).applyGlobalSwitches();
      _loggingService.debug('AppController: Global defaults applied via notifier.');

      final List<ChannelSubscriptionSetting> newSettings = _ref.read(channelListProvider);

      final actions = await _decisionService.determineActionsForApplyGlobalDefaults(oldSettings: oldSettings, newSettings: newSettings);
      _loggingService.debug('AppController: Decision service determined ${actions.length} actions for applying global defaults.');

      await _actionHandler.executeActions(actions);
      _loggingService.info('AppController: Action handler executed actions for applying global defaults.');

      _ref.refresh(scheduledNotificationsProvider);
      _loggingService.debug('AppController: Refreshed scheduled notifications provider after applying global defaults.');
    } catch (e, s) {
      _loggingService.error('AppController: Failed to apply global defaults', e, s);
    }
  }

  Future<bool> exportConfiguration() async {
    _loggingService.info('AppController: Exporting configuration...');
    try {
      final AppConfig configData = await _settingsService.exportConfiguration();
      final String configJson = jsonEncode(configData.toJson());
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, 'holodex_notifier_config.json');
      final file = File(filePath);
      await file.writeAsString(configJson);
      _loggingService.debug('AppController: Config saved to temporary file: $filePath');

      final result = await Share.shareXFiles([XFile(filePath)], text: 'Holodex Notifier Configuration', subject: 'HolodexNotifier_Config');

      if (result.status == ShareResultStatus.success) {
        _loggingService.info('AppController: Configuration exported and shared successfully.');
        return true;
      } else {
        _loggingService.warning('AppController: Configuration export sharing status: ${result.status}');
        return false;
      }
    } catch (e, s) {
      _loggingService.error('AppController: Failed to export configuration', e, s);
      return false;
    }
  }

  Future<bool> importConfiguration() async {
    _loggingService.info('AppController: Starting configuration import...');
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        _loggingService.debug('AppController: File picked for import: $filePath');
        final file = File(filePath);
        final String fileContent = await file.readAsString();
        final Map<String, dynamic> jsonMap = jsonDecode(fileContent);
        final AppConfig importedConfig = AppConfig.fromJson(jsonMap);
        _loggingService.debug('AppController: Configuration JSON parsed successfully.');

        final bool success = await _settingsService.importConfiguration(importedConfig);

        if (success) {
          _loggingService.info('AppController: Configuration imported and applied successfully.');
          await _refreshStateAfterImport();
          _loggingService.debug('AppController: UI State refreshed after import.');
          return true;
        } else {
          _loggingService.error('AppController: SettingsService reported failure during import application.');
          return false;
        }
      } else {
        _loggingService.info('AppController: File import canceled by user.');
        return false;
      }
    } catch (e, s) {
      _loggingService.error('AppController: Failed to import configuration', e, s);
      return false;
    }
  }

  Future<void> _refreshStateAfterImport() async {
    await _ref.read(channelListProvider.notifier).reloadState();

    final newFreq = await _settingsService.getPollFrequency();
    final newGroup = await _settingsService.getNotificationGrouping();
    final newDelay = await _settingsService.getDelayNewMedia();
    final newReminderLead = await _settingsService.getReminderLeadTime();
    _ref.read(pollFrequencyProvider.notifier).state = newFreq;
    _ref.read(notificationGroupingProvider.notifier).state = newGroup;
    _ref.read(delayNewMediaProvider.notifier).state = newDelay;
    _ref.read(reminderLeadTimeProvider.notifier).state = newReminderLead;

    _ref.refresh(apiKeyProvider);

    await updateGlobalSetting('pollFrequency', newFreq);
    await updateGlobalSetting('reminderLeadTime', newReminderLead);
  }

  Future<void> sendTestNotifications() async {
    _loggingService.info("AppController: Sending test notifications...");
    final DateTime now = DateTime.now();
    const String testChannelId = 'UCtestChannel';
    const String testChannelName = 'Test Channel';
    const String testAvatarUrl = 'https://yt3.googleusercontent.com/ytc/AIdro_nb5QnwxQzM8drdXb1WgsHr6O5O5w7zF9Gf9w=s176-c-k-c0x00ffffff-no-rj';

    final List<Future<void>> dispatchFutures = [];

    for (final type in NotificationEventType.values) {
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
          exampleTime = now.add(const Duration(minutes: 1)).toLocal();
          exampleRelTime = 'in 1 min';
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

      if (type == NotificationEventType.reminder) {
        instruction.copyWith(videoTitle: testVideoTitle.replaceAll('{relativeTime}', exampleRelTime));
      }

      dispatchFutures.add(
        _notificationService.showNotification(instruction).catchError((e, s) {
          _loggingService.error("Error sending test notification type $type", e, s);
        }),
      );
    }

    await Future.wait(dispatchFutures);
    _loggingService.info("AppController: Test notification dispatch attempted for all types.");
  }

  Future<void> restoreScheduledNotification(ScheduledNotificationItem itemToRestore) async {
    _loggingService.info(
      "AppController: Restoring scheduled notification for ${itemToRestore.videoData.videoId} (${itemToRestore.type.name}) at ${itemToRestore.scheduledTime}",
    );
    try {
      await _cacheService.updateDismissalStatus(itemToRestore.videoData.videoId, false);
      _loggingService.debug("AppController: Cleared dismissal status for ${itemToRestore.videoData.videoId}");

      final instruction = _createInstructionFromScheduledItem(itemToRestore);
      if (instruction == null) {
        _loggingService.error("AppController: Failed to create instruction for restoration of ${itemToRestore.videoData.videoId}");
        return;
      }

      final newNotificationId = await _notificationService.scheduleNotification(instruction: instruction, scheduledTime: itemToRestore.scheduledTime);
      if (newNotificationId == null) {
        _loggingService.error("AppController: Rescheduling notification failed for ${itemToRestore.videoData.videoId}, received null ID.");

        return;
      }
      _loggingService.info("AppController: Notification rescheduled successfully, new ID: $newNotificationId");

      if (itemToRestore.type == NotificationEventType.reminder) {
        await _cacheService.updateScheduledReminderNotificationId(itemToRestore.videoData.videoId, newNotificationId);
        await _cacheService.updateScheduledReminderTime(itemToRestore.videoData.videoId, itemToRestore.scheduledTime);
        _loggingService.debug("AppController: Updated reminder cache entry for ${itemToRestore.videoData.videoId}");
      } else if (itemToRestore.type == NotificationEventType.live) {
        await _cacheService.updateScheduledNotificationId(itemToRestore.videoData.videoId, newNotificationId);
        _loggingService.debug("AppController: Updated live cache entry for ${itemToRestore.videoData.videoId}");
      }

      _ref.refresh(scheduledNotificationsProvider);
      _ref.refresh(dismissedNotificationsNotifierProvider);
      _loggingService.debug("AppController: Refreshed providers after restore.");
    } catch (e, s) {
      _loggingService.error("AppController: Failed to restore notification for ${itemToRestore.videoData.videoId}", e, s);
    }
  }

  NotificationInstruction? _createInstructionFromScheduledItem(ScheduledNotificationItem item) {
    final video = item.videoData;

    return NotificationInstruction(
      videoId: video.videoId,
      eventType: item.type,
      channelId: video.channelId,
      channelName: video.channelName,
      videoTitle: video.videoTitle,
      videoType: video.videoType,
      channelAvatarUrl: video.channelAvatarUrl,
      availableAt: DateTime.tryParse(video.startScheduled ?? video.availableAt) ?? item.scheduledTime,
      videoThumbnailUrl: video.thumbnailUrl,
    );
  }
}
