import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/main.dart';

final pollFrequencyProvider = StateProvider<Duration>((ref) {
  return const Duration(minutes: 10);
});

final notificationGroupingProvider = StateProvider<bool>((ref) {
  return true;
});

final delayNewMediaProvider = StateProvider<bool>((ref) {
  return false;
});

final reminderLeadTimeProvider = StateProvider<Duration>((ref) {
  return Duration.zero;
});

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
    try {
      await _settingsService.setApiKey(valueToStore);
      state = AsyncValue.data(valueToStore);
      _logger.debug("[ApiKeyNotifier] API Key updated successfully in storage and state.");
    } catch (e, s) {
      _logger.error("[ApiKeyNotifier] Error saving API key", e, s);
      state = AsyncValue.error(e, s).copyWithPrevious(state) as AsyncValue<String?>;
      rethrow;
    }
  }
}

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, AsyncValue<String?>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  final logger = ref.watch(loggingServiceProvider);
  return ApiKeyNotifier(settingsService, logger);
});

final globalNewMediaDefaultProvider = StateProvider<bool>((ref) => true);
final globalMentionsDefaultProvider = StateProvider<bool>((ref) => true);
final globalLiveDefaultProvider = StateProvider<bool>((ref) => true);
final globalUpdateDefaultProvider = StateProvider<bool>((ref) => true);
final globalMembersOnlyDefaultProvider = StateProvider<bool>((ref) => false);
final globalClipsDefaultProvider = StateProvider<bool>((ref) => false);
