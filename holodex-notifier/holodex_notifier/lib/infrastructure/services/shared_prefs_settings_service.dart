// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\infrastructure\services\shared_prefs_settings_service.dart
import 'dart:convert'; // For jsonEncode/Decode
import 'dart:math';

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:holodex_notifier/domain/models/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/interfaces/secure_storage_service.dart'; // Import Secure Storage Interface
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart'; // Import the model

// Define keys for SharedPreferences
const String _keyPollFrequencyMinutes = 'settings_pollFrequencyMinutes';
const String _keyNotificationGrouping = 'settings_notificationGrouping';
const String _keyDelayNewMedia = 'settings_delayNewMedia';
const String _keyReminderLeadTimeMinutes = 'settings_reminderLeadTimeMinutes';
const String _keyLastPollTime = 'settings_lastPollTime';
const String _keyChannelSubscriptions = 'settings_channelSubscriptions';
const String _apiKeySecureStorageKey = 'holodex_api_key';
const String _keyMainServicesReady = 'app_main_services_ready'; // Key for readiness flag
const String _keyIsFirstLaunch = 'app_is_first_launch'; // Key for first launch flag

class SharedPrefsSettingsService implements ISettingsService {
  // Dependencies
  late final SharedPreferences _prefs;
  final ISecureStorageService _secureStorageService; // Inject Secure Storage

  // Defaults
  static const Duration _defaultPollFrequency = Duration(minutes: 10);
  static const bool _defaultNotificationGrouping = true;
  static const bool _defaultDelayNewMedia = false;
  static const Duration _defaultReminderLeadTime = Duration.zero;

  // Inject ISecureStorageService
  SharedPrefsSettingsService(this._secureStorageService);

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print("[SharedPrefsSettingsService] Instance initialized.");
    }
  }

  // --- Helper to reload prefs ---
  Future<void> _ensureFreshPrefs() async {
    // This reload might be expensive if called very frequently,
    // but necessary if background updates are possible.
    await _prefs.reload();
  }

  // --- Simple Settings ---

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
    // Store 0 if duration is zero or negative
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

  // --- API Key (Delegated) ---

  @override
  Future<String?> getApiKey() async {
    // Read from secure storage
    return await _secureStorageService.read(_apiKeySecureStorageKey);
  }

  @override
  Future<void> setApiKey(String? apiKey) async {
    // Write to secure storage
    final String? valueToStore = (apiKey != null && apiKey.isEmpty) ? null : apiKey;
    await _secureStorageService.write(_apiKeySecureStorageKey, valueToStore);
  }

  // --- Channel Subscriptions ---

  @override
  Future<List<ChannelSubscriptionSetting>> getChannelSubscriptions() async {
    await _ensureFreshPrefs();
    final List<String>? jsonList = _prefs.getStringList(_keyChannelSubscriptions);
    if (jsonList == null) {
      return []; // Return empty list if no data saved
    }

    final List<ChannelSubscriptionSetting> settings = [];
    for (final jsonString in jsonList) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        settings.add(ChannelSubscriptionSetting.fromJson(jsonMap));
      } catch (e) {
        // TODO: Use logging service
        print('Error decoding channel subscription setting: $e. Skipping invalid entry: $jsonString');
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
              } catch (e) {
                // TODO: Use logging service
                print('Error encoding channel subscription setting: $e for channel ${setting.channelId}');
                return null; // Return null for invalid entries
              }
            })
            .whereType<String>()
            .toList(); // Filter out nulls from failed encodings

    await _prefs.setStringList(_keyChannelSubscriptions, jsonList);
  }

  @override
  Future<void> updateChannelAvatar(String channelId, String? newAvatarUrl) async {
    await _ensureFreshPrefs(); // Ensure we have latest data if called concurrently

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
      // Only update and save if the URL has actually changed
      if (currentSetting.avatarUrl != newAvatarUrl) {
        if (kDebugMode) {
          print("[SharedPrefsSettingsService] Updating avatar for $channelId from ${currentSetting.avatarUrl} to $newAvatarUrl");
        }
        // Create updated list
        final updatedSettings = List<ChannelSubscriptionSetting>.from(currentSettings);
        updatedSettings[foundIndex] = currentSetting.copyWith(avatarUrl: newAvatarUrl);
        // Save the updated list
        await saveChannelSubscriptions(updatedSettings);
      } else {
        // Log that no update was needed (optional)
        if (kDebugMode) {
          print("[SharedPrefsSettingsService] Avatar URL for $channelId is already up-to-date ($newAvatarUrl). No save needed.");
        }
      }
    } else {
      // Log warning: Attempted to update avatar for a non-existent channel subscription
      print("[SharedPrefsSettingsService] WARNING: Attempted to update avatar for non-subscribed channel ID: $channelId");
    }
  }

  // --- Initialization Readiness Flag ---

  @override
  Future<bool> getMainServicesReady() async {
    await _ensureFreshPrefs(); // Reload before reading
    final bool ready = _prefs.getBool(_keyMainServicesReady) ?? false; // Default to false if not found
    if (kDebugMode) {
      print("[SharedPrefsSettingsService] Main Services Ready flag READ as: $ready");
    }
    return ready;
  }

  @override
  Future<void> setMainServicesReady(bool ready) async {
    // No need to reload before write
    await _prefs.setBool(_keyMainServicesReady, ready);
    if (kDebugMode) {
      print("[SharedPrefsSettingsService] Main Services Ready flag SET to: $ready");
    }
  }

  // --- First Launch Flag ---
  @override
  Future<bool> getIsFirstLaunch() async {
    await _ensureFreshPrefs();
    // Default to true if the key doesn't exist yet
    return _prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  @override
  Future<void> setIsFirstLaunch(bool isFirst) async {
    await _prefs.setBool(_keyIsFirstLaunch, isFirst);
    if (kDebugMode) {
      print("[SharedPrefsSettingsService] IsFirstLaunch flag SET to: $isFirst");
    }
  }

  // --- Config Export/Import ---
  @override
  Future<AppConfig> exportConfiguration() async {
    // Read current settings
    final freq = await getPollFrequency();
    final grouping = await getNotificationGrouping();
    final delay = await getDelayNewMedia();
    final reminderLead = await getReminderLeadTime(); // {{ Get reminder lead time }}
    final channels = await getChannelSubscriptions();

    return AppConfig(
      pollFrequencyMinutes: freq.inMinutes,
      notificationGrouping: grouping,
      delayNewMedia: delay,
      reminderLeadTimeMinutes: reminderLead.inMinutes, // {{ Export reminder lead time }}
      channelSubscriptions: channels,
      version: 1, // Current version
    );
  }

  @override
  Future<bool> importConfiguration(AppConfig config) async {
    // ... (validation) ...

    print("[SharedPrefsSettingsService] Importing configuration version ${config.version}...");
    try {
      // Apply settings
      await setPollFrequency(Duration(minutes: config.pollFrequencyMinutes));
      await setNotificationGrouping(config.notificationGrouping);
      await setDelayNewMedia(config.delayNewMedia);
       // {{ Import reminder lead time }}
      await setReminderLeadTime(Duration(minutes: max(0, config.reminderLeadTimeMinutes))); // Ensure non-negative

      // Overwrite channel subscriptions
      await saveChannelSubscriptions(config.channelSubscriptions);
      // DO NOT import API key or last poll time etc.

      print("[SharedPrefsSettingsService] Config import successful.");
      return true;
    } catch (e) {
      print("[SharedPrefsSettingsService] Config Import Error during apply: $e");
      return false;
    }
  }
}
