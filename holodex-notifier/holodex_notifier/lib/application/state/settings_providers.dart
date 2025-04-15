// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\application\state\settings_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/main.dart';
// REMOVED: No longer need to import SettingsService or main.dart here

// --- StateProviders now only return defaults ---
// The actual initial values are loaded asynchronously in main.dart and provided via overrides.

final pollFrequencyProvider = StateProvider<Duration>((ref) {
  // This logs when the provider is created *before* the override from main.dart is applied.
  //print("pollFrequencyProvider initialized with DEFAULT value (Duration(minutes: 10)).");
  return const Duration(minutes: 10); // Default value
});

final notificationGroupingProvider = StateProvider<bool>((ref) {
  //print("notificationGroupingProvider initialized with DEFAULT value (true).");
  return true; // Default value
});

final delayNewMediaProvider = StateProvider<bool>((ref) {
  //print("delayNewMediaProvider initialized with DEFAULT value (false).");
  return false; // Default value
});

final reminderLeadTimeProvider = StateProvider<Duration>((ref) {
  // Default value, will be overridden by main.dart
  return Duration.zero;
});

// Define the StateNotifier
class ApiKeyNotifier extends StateNotifier<AsyncValue<String?>> {
  final ISettingsService _settingsService;
  final ILoggingService _logger;

  ApiKeyNotifier(this._settingsService, this._logger) : super(const AsyncValue.loading()) {
    _loadInitialKey();
  }

  Future<void> _loadInitialKey() async {
    _logger.debug("[ApiKeyNotifier] Loading initial API key...");
    try {
      final key = await _settingsService.getApiKey();
      state = AsyncValue.data(key);
      _logger.debug("[ApiKeyNotifier] Initial API key loaded: ${key == null || key.isEmpty ? 'Not Set' : 'Set'}");
    } catch (e, s) {
      _logger.error("[ApiKeyNotifier] Error loading initial API key", e, s);
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateApiKey(String? newKey) async {
    final String? valueToStore = (newKey != null && newKey.isEmpty) ? null : newKey;
    _logger.debug("[ApiKeyNotifier] Attempting to update API Key to: '$valueToStore'");
    // Optimistically update UI state to loading while saving
    // state = AsyncLoading<String?>().copyWithPrevious(state); // Optional: Show loading on change
    try {
      await _settingsService.setApiKey(valueToStore);
      // Set final state after successful save
      state = AsyncValue.data(valueToStore);
      _logger.debug("[ApiKeyNotifier] API Key updated successfully in storage and state.");
    } catch (e, s) {
      _logger.error("[ApiKeyNotifier] Error saving API key", e, s);
      // Restore previous state on error
      state = AsyncValue.error(e, s).copyWithPrevious(state) as AsyncValue<String?>; // Keep previous data available
      // Rethrow maybe? Or handle in UI
      rethrow;
    }
  }
}

// Define the StateNotifierProvider
final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, AsyncValue<String?>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  final logger = ref.watch(loggingServiceProvider);
  return ApiKeyNotifier(settingsService, logger);
});

// --- Global Switch defaults remain simple states ---
// These don't store persistent state, they are just UI state for the switches themselves.
// GLOBAL SETTINGS DEFAULTS (move to config file later)
final globalNewMediaDefaultProvider = StateProvider<bool>((ref) => true);
final globalMentionsDefaultProvider = StateProvider<bool>((ref) => true);
final globalLiveDefaultProvider = StateProvider<bool>((ref) => true);
final globalUpdateDefaultProvider = StateProvider<bool>((ref) => true);
final globalMembersOnlyDefaultProvider = StateProvider<bool>((ref) => false);
final globalClipsDefaultProvider = StateProvider<bool>((ref) => false);
