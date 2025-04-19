import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/models/app_config.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/interfaces/secure_storage_service.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';

const String _keyPollFrequencyMinutes = 'settings_pollFrequencyMinutes';
const String _keyNotificationGrouping = 'settings_notificationGrouping';
const String _keyDelayNewMedia = 'settings_delayNewMedia';
const String _keyReminderLeadTimeMinutes = 'settings_reminderLeadTimeMinutes';
const String _keyLastPollTime = 'settings_lastPollTime';
const String _keyChannelSubscriptions = 'settings_channelSubscriptions';
const String _apiKeySecureStorageKey = 'holodex_api_key';
const String _keyMainServicesReady = 'app_main_services_ready';
const String _keyIsFirstLaunch = 'app_is_first_launch';
const String _keyNotificationFormatConfig = 'settings_notificationFormatConfig';
const String _keyScheduledFilterTypes = 'settings_scheduledFilterTypes';

class SharedPrefsSettingsService implements ISettingsService {
  late final SharedPreferences _prefs;
  final ISecureStorageService _secureStorageService;
  final ILoggingService _logger;

  static const Duration _defaultPollFrequency = Duration(minutes: 10);
  static const bool _defaultNotificationGrouping = false;
  static const bool _defaultDelayNewMedia = false;
  static const Duration _defaultReminderLeadTime = Duration.zero;

  SharedPrefsSettingsService(this._secureStorageService, this._logger);

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _logger.debug("[SharedPrefsSettingsService] Instance initialized.");
  }

  Future<void> _ensureFreshPrefs() async {
    await _prefs.reload();
  }

  @override
  Future<Duration> getPollFrequency() async {
    await _ensureFreshPrefs();
    final minutes = _prefs.getInt(_keyPollFrequencyMinutes) ?? _defaultPollFrequency.inMinutes;
    return Duration(minutes: minutes);
  }

  @override
  Future<void> setPollFrequency(Duration frequency) async {
    await _prefs.setInt(_keyPollFrequencyMinutes, frequency.inMinutes);
  }

  @override
  Future<bool> getNotificationGrouping() async {
    await _ensureFreshPrefs();
    return _prefs.getBool(_keyNotificationGrouping) ?? _defaultNotificationGrouping;
  }

  @override
  Future<void> setNotificationGrouping(bool enabled) async {
    await _prefs.setBool(_keyNotificationGrouping, enabled);
  }

  @override
  Future<bool> getDelayNewMedia() async {
    await _ensureFreshPrefs();
    return _prefs.getBool(_keyDelayNewMedia) ?? _defaultDelayNewMedia;
  }

  @override
  Future<void> setDelayNewMedia(bool enabled) async {
    await _prefs.setBool(_keyDelayNewMedia, enabled);
  }

  @override
  Future<Duration> getReminderLeadTime() async {
    await _ensureFreshPrefs();
    final minutes = _prefs.getInt(_keyReminderLeadTimeMinutes) ?? _defaultReminderLeadTime.inMinutes;
    return Duration(minutes: minutes);
  }

  @override
  Future<void> setReminderLeadTime(Duration leadTime) async {
    final minutesToStore = leadTime.isNegative ? 0 : leadTime.inMinutes;
    await _prefs.setInt(_keyReminderLeadTimeMinutes, minutesToStore);
  }

  @override
  Future<DateTime?> getLastPollTime() async {
    await _ensureFreshPrefs();
    final timestamp = _prefs.getInt(_keyLastPollTime);
    return timestamp == null ? null : DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  @override
  Future<void> setLastPollTime(DateTime time) async {
    await _prefs.setInt(_keyLastPollTime, time.millisecondsSinceEpoch);
  }

  @override
  Future<String?> getApiKey() async {
    return await _secureStorageService.read(_apiKeySecureStorageKey);
  }

  @override
  Future<void> setApiKey(String? apiKey) async {
    final String? valueToStore = (apiKey != null && apiKey.isEmpty) ? null : apiKey;
    await _secureStorageService.write(_apiKeySecureStorageKey, valueToStore);
  }

  @override
  Future<List<ChannelSubscriptionSetting>> getChannelSubscriptions() async {
    await _ensureFreshPrefs();
    final List<String>? jsonList = _prefs.getStringList(_keyChannelSubscriptions);
    if (jsonList == null) {
      return [];
    }

    final List<ChannelSubscriptionSetting> settings = [];
    for (final jsonString in jsonList) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        settings.add(ChannelSubscriptionSetting.fromJson(jsonMap));
      } catch (e, s) {
        _logger.error('Error decoding channel subscription setting. Skipping invalid entry: $jsonString', e, s);
      }
    }
    return settings;
  }

  @override
  Future<void> saveChannelSubscriptions(List<ChannelSubscriptionSetting> channels) async {
    final List<String> jsonList =
        channels
            .map((setting) {
              try {
                return jsonEncode(setting.toJson());
              } catch (e, s) {
                _logger.error('Error encoding channel subscription setting for channel ${setting.channelId}', e, s);
                return null;
              }
            })
            .whereType<String>()
            .toList();

    await _prefs.setStringList(_keyChannelSubscriptions, jsonList);
  }

  @override
  Future<void> updateChannelAvatar(String channelId, String? newAvatarUrl) async {
    await _ensureFreshPrefs();

    final List<ChannelSubscriptionSetting> currentSettings = await getChannelSubscriptions();
    int foundIndex = -1;
    for (int i = 0; i < currentSettings.length; i++) {
      if (currentSettings[i].channelId == channelId) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex != -1) {
      final currentSetting = currentSettings[foundIndex];
      if (currentSetting.avatarUrl != newAvatarUrl) {
        if (kDebugMode) {
          print("[SharedPrefsSettingsService] Updating avatar for $channelId from ${currentSetting.avatarUrl} to $newAvatarUrl");
        }
        final updatedSettings = List<ChannelSubscriptionSetting>.from(currentSettings);
        updatedSettings[foundIndex] = currentSetting.copyWith(avatarUrl: newAvatarUrl);
        await saveChannelSubscriptions(updatedSettings);
      } else {
        if (kDebugMode) {
          print("[SharedPrefsSettingsService] Avatar URL for $channelId is already up-to-date ($newAvatarUrl). No save needed.");
        }
      }
    } else {
      _logger.warning("[SharedPrefsSettingsService] Attempted to update avatar for non-subscribed channel ID: $channelId");
    }
  }

  @override
  Future<bool> getMainServicesReady() async {
    await _ensureFreshPrefs();
    final bool ready = _prefs.getBool(_keyMainServicesReady) ?? false;
    if (kDebugMode) {
      print("[SharedPrefsSettingsService] Main Services Ready flag READ as: $ready");
    }
    return ready;
  }

  @override
  Future<void> setMainServicesReady(bool ready) async {
    await _prefs.setBool(_keyMainServicesReady, ready);
    if (kDebugMode) {
      print("[SharedPrefsSettingsService] Main Services Ready flag SET to: $ready");
    }
  }

  @override
  Future<bool> getIsFirstLaunch() async {
    await _ensureFreshPrefs();
    return _prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  @override
  Future<void> setIsFirstLaunch(bool isFirst) async {
    await _prefs.setBool(_keyIsFirstLaunch, isFirst);
    if (kDebugMode) {
      print("[SharedPrefsSettingsService] IsFirstLaunch flag SET to: $isFirst");
    }
  }

  @override
  Future<AppConfig> exportConfiguration() async {
    final freq = await getPollFrequency();
    final grouping = await getNotificationGrouping();
    final delay = await getDelayNewMedia();
    final reminderLead = await getReminderLeadTime();
    final channels = await getChannelSubscriptions();

    return AppConfig(
      pollFrequencyMinutes: freq.inMinutes,
      notificationGrouping: grouping,
      delayNewMedia: delay,
      reminderLeadTimeMinutes: reminderLead.inMinutes,
      channelSubscriptions: channels,
      version: 1,
    );
  }

  @override
  Future<bool> importConfiguration(AppConfig config) async {
    _logger.info("[SharedPrefsSettingsService] Importing configuration version ${config.version}...");
    try {
      await setPollFrequency(Duration(minutes: config.pollFrequencyMinutes));
      await setNotificationGrouping(config.notificationGrouping);
      await setDelayNewMedia(config.delayNewMedia);
      await setReminderLeadTime(Duration(minutes: max(0, config.reminderLeadTimeMinutes)));

      await saveChannelSubscriptions(config.channelSubscriptions);

      _logger.info("[SharedPrefsSettingsService] Config import successful.");
      return true;
    } catch (e, s) {
      _logger.error("[SharedPrefsSettingsService] Config Import Error during apply", e, s);
      return false;
    }
  }

  @override
  Future<NotificationFormatConfig> getNotificationFormatConfig() async {
    await _ensureFreshPrefs();
    final String? jsonString = _prefs.getString(_keyNotificationFormatConfig);
    if (jsonString != null) {
      try {
        final jsonMap = jsonDecode(jsonString);
        return NotificationFormatConfig.fromJson(jsonMap);
      } catch (e, s) {
        _logger.warning("Error decoding NotificationFormatConfig JSON. Returning default.", e, s);
      }
    }
    return NotificationFormatConfig.defaultConfig();
  }

  @override
  Future<void> setNotificationFormatConfig(NotificationFormatConfig config) async {
    try {
      final jsonString = jsonEncode(config.toJson());
      await _prefs.setString(_keyNotificationFormatConfig, jsonString);
    } catch (e, s) {
      _logger.error("Error encoding NotificationFormatConfig JSON", e, s);
    }
  }

  @override
  Future<Set<NotificationEventType>> getScheduledFilterTypes() async {
    await _ensureFreshPrefs();
    final List<String>? typeNames = _prefs.getStringList(_keyScheduledFilterTypes);
    if (typeNames == null) {
      return {NotificationEventType.live, NotificationEventType.reminder};
    }
    try {
      return typeNames.map((name) => NotificationEventType.values.firstWhere((e) => e.name == name)).toSet();
    } catch (e) {
      _logger.warning("Error parsing saved scheduled filter types: $typeNames. Returning default.", e);
      return {NotificationEventType.live, NotificationEventType.reminder};
    }
  }

  @override
  Set<NotificationEventType> getScheduledFilterTypesSync() {
    final prefs = _prefs;
    final typeStrings = prefs.getStringList(_keyScheduledFilterTypes) ?? [];
    return typeStrings.map((str) => NotificationEventType.values.byName(str)).toSet();
  }

  @override
  Future<void> setScheduledFilterTypes(Set<NotificationEventType> types) async {
    final List<String> typeNames = types.map((e) => e.name).toList();
    await _prefs.setStringList(_keyScheduledFilterTypes, typeNames);
    _logger.debug("Saved scheduled filter types: $typeNames");
  }
}
