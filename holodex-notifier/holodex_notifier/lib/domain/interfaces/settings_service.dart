// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\interfaces\settings_service.dart
import 'package:holodex_notifier/domain/models/app_config.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart'; // Import the model

/// Defines the contract for managing user settings and application state.
abstract class ISettingsService {
  /// Initializes the settings service, potentially loading defaults or migrating.
  Future<void> initialize();

  // --- Simple Settings ---

  /// Gets the background polling frequency.
  Future<Duration> getPollFrequency();

  /// Sets the background polling frequency.
  Future<void> setPollFrequency(Duration frequency);

  /// Gets whether notifications should be grouped.
  Future<bool> getNotificationGrouping();

  /// Sets whether notifications should be grouped.
  Future<void> setNotificationGrouping(bool enabled);

  /// Gets whether new media notifications should be delayed until scheduled time.
  Future<bool> getDelayNewMedia();

  /// Sets whether new media notifications should be delayed until scheduled time.
  Future<void> setDelayNewMedia(bool enabled);

  /// Gets the timestamp of the last successful background poll.
  Future<DateTime?> getLastPollTime();

  /// Sets the timestamp of the last successful background poll.
  Future<void> setLastPollTime(DateTime time);

  // --- API Key (Delegated to Secure Storage) ---

  /// Gets the Holodex API Key securely. Returns null if not set.
  Future<String?> getApiKey();

  /// Sets the Holodex API Key securely. Pass null to clear.
  Future<void> setApiKey(String? apiKey);

  // --- Channel List & Settings ---

  /// Gets the list of subscribed channels and their notification settings.
  Future<List<ChannelSubscriptionSetting>> getChannelSubscriptions();

  /// Saves the list of subscribed channels and their settings.
  Future<void> saveChannelSubscriptions(List<ChannelSubscriptionSetting> channels);

  /// Updates the avatar URL for a specific channel subscription setting.
  Future<void> updateChannelAvatar(String channelId, String? newAvatarUrl); // <-- ADD THIS LINE

  // --- Initialization Readiness Flag ---

  /// Checks if the main isolate has finished initializing its critical services.
  Future<bool> getMainServicesReady();

  /// Sets the flag indicating whether main isolate services are ready.
  Future<void> setMainServicesReady(bool ready);

  // --- First Launch Flag ---
  Future<bool> getIsFirstLaunch();
  Future<void> setIsFirstLaunch(bool isFirst);

  // --- Config Export/Import ---
  /// Exports the current non-sensitive configuration.
  Future<AppConfig> exportConfiguration();

  /// Imports and applies the provided configuration.
  /// Returns true on success, false on failure (e.g., validation error).
  Future<bool> importConfiguration(AppConfig config);
}
