// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\application\state\channel_providers.dart
import 'dart:async'; // For Future used in _saveState

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart'; // Import Settings Service Interface
import 'package:holodex_notifier/domain/interfaces/logging_service.dart'; // For Logger
import 'package:holodex_notifier/main.dart'; // For settingsServiceProvider, apiServiceProvider, loggingServiceProvider
import 'package:holodex_notifier/application/state/settings_providers.dart'; // For global defaults

// Provider for the list of subscribed channels and their settings
final channelListProvider = StateNotifierProvider<ChannelListNotifier, List<ChannelSubscriptionSetting>>((ref) {
  // Inject SettingsService & Logger
  final settingsService = ref.watch(settingsServiceProvider);
  final logger = ref.watch(loggingServiceProvider);

  // Pass ref, service and logger to the notifier
  final notifier = ChannelListNotifier(ref, settingsService, logger, []);

  // Trigger initial load when the provider is first read
  notifier.loadInitialState();

  return notifier;
}, name: 'channelListProvider');

class ChannelListNotifier extends StateNotifier<List<ChannelSubscriptionSetting>> {
  final Ref _ref;
  final ISettingsService _settingsService; // Add SettingsService dependency
  final ILoggingService _logger; // Add Logger dependency

  // Update constructor
  ChannelListNotifier(this._ref, this._settingsService, this._logger, List<ChannelSubscriptionSetting> initialState) : super(initialState);

  /// Loads the initial list from persistent storage.
  Future<void> loadInitialState() async {
    _logger.info("ChannelListNotifier: Loading initial state...");
    try {
      final loadedState = await _settingsService.getChannelSubscriptions();
      // Only update state if it's different to avoid unnecessary rebuilds at startup
      // A simple length check can prevent some unnecessary deep equality checks
      if (state.length != loadedState.length || state != loadedState) {
        state = loadedState;
        _logger.info("ChannelListNotifier: Loaded ${state.length} channels.");
      } else {
        _logger.info("ChannelListNotifier: Loaded state matches initial state.");
      }
    } catch (e, s) {
      _logger.error("ChannelListNotifier: Error loading initial state", e, s);
      // Handle error appropriately, maybe set state to empty list?
      state = [];
    }
  }

  /// Reloads the list from persistent storage.
  Future<void> reloadState() async {
    _logger.info("ChannelListNotifier: Reloading state from storage...");
    await _reloadFromStorage(isInitialLoad: false); // Use helper
  }

  // --- Internal Helper for Loading/Reloading ---
  Future<void> _reloadFromStorage({required bool isInitialLoad}) async {
    try {
      final loadedState = await _settingsService.getChannelSubscriptions();
      // Only update state if it's different to avoid unnecessary rebuilds
      // This check prevents infinite loops if a reload triggers another reload indirectly.
      if (!mounted) return; // Check if notifier is still alive

      // Use Set comparison for efficient equality check regardless of order
      final currentStateSet = Set.from(state.map((e) => e.channelId));
      final loadedStateSet = Set.from(loadedState.map((e) => e.channelId));

      // Basic check: if IDs differ or content differs (deep equality might be too slow)
      bool changed = currentStateSet.length != loadedStateSet.length || !currentStateSet.containsAll(loadedStateSet);

      // If IDs are the same, do a slightly deeper check for avatar differences
      if (!changed && state.length == loadedState.length) {
        final currentAvatars = Map.fromEntries(state.map((e) => MapEntry(e.channelId, e.avatarUrl)));
        for (final loaded in loadedState) {
          if (currentAvatars[loaded.channelId] != loaded.avatarUrl) {
            changed = true;
            break;
          }
        }
      }

      if (changed) {
        state = loadedState;
        if (!isInitialLoad) {
          _logger.info("ChannelListNotifier: Reloaded state with changes (${state.length} channels).");
        } else {
          _logger.info("ChannelListNotifier: Loaded initial state (${state.length} channels).");
        }
      } else {
        if (!isInitialLoad) {
          _logger.info("ChannelListNotifier: Reloaded state, no changes detected.");
        } else {
          _logger.info("ChannelListNotifier: Loaded initial state matches current state.");
        }
      }
    } catch (e, s) {
      _logger.error("ChannelListNotifier: Error ${isInitialLoad ? 'loading initial' : 'reloading'} state", e, s);
      if (mounted) {
        // Handle error appropriately, maybe set state to empty list or previous state?
        // Setting to empty on error might be confusing if it previously had data.
        // Consider adding an error state to the provider if needed. For now, keep previous state.
        _logger.warning("ChannelListNotifier: State kept unchanged due to reload error.");
      }
    }
  }
  // --- End Internal Helper ---

  // --- State Modification Methods ---

  void addChannel(ChannelSubscriptionSetting channel) {
    if (state.any((existing) => existing.channelId == channel.channelId)) {
      _logger.warning("ChannelListNotifier: Channel ${channel.channelId} already exists, cannot add.");
      return;
    }
    _logger.debug("ChannelListNotifier: Adding channel ${channel.channelId}");
    state = [...state, channel];
    _saveState(); // Call save helper
  }

  void removeChannel(String channelId) {
    _logger.debug("ChannelListNotifier: Removing channel $channelId");
    state = state.where((c) => c.channelId != channelId).toList();
    _saveState(); // Call save helper
  }

  void updateChannelSettings(String channelId, {bool? newMedia, bool? mentions, bool? live, bool? updates, bool? membersOnly, bool? clips}) {
    _logger.info("ChannelListNotifier: Updating settings for $channelId (New:$newMedia, Mention:$mentions, Live:$live, Update:$updates, Members:$membersOnly, Clips:$clips)");

    final index = state.indexWhere((c) => c.channelId == channelId);
    if (index == -1) return;

    final currentSetting = state[index];
    final updatedSetting = currentSetting.copyWith(
      notifyNewMedia: newMedia ?? currentSetting.notifyNewMedia,
      notifyMentions: mentions ?? currentSetting.notifyMentions,
      notifyLive: live ?? currentSetting.notifyLive,
      notifyUpdates: updates ?? currentSetting.notifyUpdates,
      notifyMembersOnly: membersOnly ?? currentSetting.notifyMembersOnly,
      notifyClips: clips ?? currentSetting.notifyClips,
    );

    final newState = List<ChannelSubscriptionSetting>.from(state);
    newState[index] = updatedSetting;
    state = newState;
    _saveState(); // Call save helper
  }

  void reorderChannels(int oldIndex, int newIndex) {
    _logger.debug("ChannelListNotifier: Reordering from $oldIndex to $newIndex");
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex > state.length) return; // Allow moving to end

    final item = state[oldIndex];
    final newState = List<ChannelSubscriptionSetting>.from(state);
    newState.removeAt(oldIndex);

    // Adjust index if moving downwards
    final adjustedNewIndex = (oldIndex < newIndex) ? newIndex - 1 : newIndex;
    // Ensure index is within bounds after potential removal/adjustment
    final finalIndex = adjustedNewIndex.clamp(0, newState.length);

    newState.insert(finalIndex, item);

    state = newState;
    _saveState(); // Call save helper
  }

  void applyGlobalSwitches() {
    _logger.info("ChannelListNotifier: Applying global notification defaults to all channels.");
    final globalNewMedia = _ref.read(globalNewMediaDefaultProvider);
    final globalMentions = _ref.read(globalMentionsDefaultProvider);
    final globalLive = _ref.read(globalLiveDefaultProvider);
    final globalUpdate = _ref.read(globalUpdateDefaultProvider);
        final globalMembersOnly = _ref.read(globalMembersOnlyDefaultProvider);
    final globalClips = _ref.read(globalClipsDefaultProvider);

    state = [
      for (final channel in state)
        channel.copyWith(notifyNewMedia: globalNewMedia, notifyMentions: globalMentions, notifyLive: globalLive, notifyUpdates: globalUpdate,
          notifyMembersOnly: globalMembersOnly,
          notifyClips: globalClips,),
    ];
    _saveState(); // Call save helper
  }

  // --- Persistence Helper ---

  /// Saves the current state list to persistent storage.
  Future<void> _saveState() async {
    _logger.info("ChannelListNotifier: Saving state (${state.length} channels)...");
    try {
      await _settingsService.saveChannelSubscriptions(state);
      _logger.info("ChannelListNotifier: State saved successfully.");
    } catch (e, s) {
      _logger.error("ChannelListNotifier: Error saving state", e, s);
      // Handle error appropriately (e.g., log, maybe signal UI via another provider)
    }
  }
}

// Custom Exception for API Key requirement
class ApiKeyRequiredException implements Exception {
  final String message;
  ApiKeyRequiredException([this.message = 'API Key is required for this operation.']);
  @override
  String toString() => message;
}

// FutureProvider for debounced search execution
final debouncedChannelSearchProvider = FutureProvider.autoDispose<List<Channel>>(
  (ref) async {
    final query = ref.watch(channelSearchQueryProvider);
    // --- Watch the AsyncValue ---
    final apiKeyAsyncValue = ref.watch(apiKeyProvider);
    final apiService = ref.watch(apiServiceProvider);
    final logger = ref.watch(loggingServiceProvider);

    // --- Extract the key value ---
    final String? apiKey = apiKeyAsyncValue.valueOrNull;

    logger.debug(
      '[Debounced Search] Triggered. Query: "$query", API Key State: isLoading=${apiKeyAsyncValue.isLoading}, hasError=${apiKeyAsyncValue.hasError}, Key Set: ${apiKey != null && apiKey.isNotEmpty}',
    );

    // --- Handle loading/error states from apiKeyProvider ---
    if (apiKeyAsyncValue.isLoading) {
      logger.debug('[Debounced Search] API Key is loading. Returning empty list for now.');
      return []; // Or throw a specific loading error if preferred
    }
    if (apiKeyAsyncValue.hasError) {
      logger.error('[Debounced Search] API Key provider has error: ${apiKeyAsyncValue.error}. Throwing exception.');
      throw ApiKeyRequiredException('Failed to load API Key setting. Please check Settings.');
    }
    // --- End Handle loading/error ---

    // Condition 0: Check API Key value
    if (apiKey == null || apiKey.isEmpty) {
      logger.warning('[Debounced Search] API Key missing or empty. Throwing ApiKeyRequiredException.');
      throw ApiKeyRequiredException('Please enter your Holodex API Key in the settings first.');
    }

    // Condition 1: Don't search if query is too short
    if (query.length < 3) {
      logger.debug('[Debounced Search] Query too short ("$query"). Returning empty list.');
      return [];
    }

    logger.debug('[Debounced Search] Debouncing for 1000ms...');
    await Future.delayed(const Duration(milliseconds: 1000));
    logger.debug('[Debounced Search] Debounce finished.');

    // Staleness check for query
    final currentQuery = ref.read(channelSearchQueryProvider);
    if (query != currentQuery) {
      logger.debug(
        '[Debounced Search] Stale query detected ("$query" vs "$currentQuery"). Proceeding with old query result (will be replaced by new one soon).',
      );
      // Let it complete, new query will trigger another run
    }

    // Check query length again
    if (currentQuery.length < 3) {
      logger.debug('[Debounced Search] Query became too short after debounce ("$currentQuery"). Returning empty list.');
      return [];
    }

    // --- Check API Key value again after debounce ---
    // Need to re-read the provider *value* after debounce, not just rely on the initial read
    final currentApiKeyAsyncValue = ref.read(apiKeyProvider); // Use read for latest value *after* debounce
    final currentApiKey = currentApiKeyAsyncValue.valueOrNull;

    if (currentApiKey == null || currentApiKey.isEmpty) {
      logger.warning('[Debounced Search] API Key missing or empty after debounce. Throwing ApiKeyRequiredException.');
      throw ApiKeyRequiredException('Please enter your Holodex API Key in the settings first.');
    }
    // --- End Check API Key value ---

    logger.info('[Debounced Search] Executing search for channel: "$currentQuery"');
    try {
      final results = await apiService.searchChannels(currentQuery); // Use currentQuery
      logger.info('[Debounced Search] Found ${results.length} channels for "$currentQuery".');
      return results;
    } catch (e, s) {
      logger.error('[Debounced Search] Error searching channels for "$currentQuery"', e, s);
      rethrow;
    }
  },
  dependencies: [
    channelSearchQueryProvider,
    apiKeyProvider, // Keep dependency on the provider itself
    apiServiceProvider,
    loggingServiceProvider,
  ],
  name: 'debouncedChannelSearchProvider',
);

// Provider for channel search query
final channelSearchQueryProvider = StateProvider<String>((ref) {
  // No need for complex logic or onDispose here anymore
  return '';
});
