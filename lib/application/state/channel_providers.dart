import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';

final channelListProvider = StateNotifierProvider<ChannelListNotifier, List<ChannelSubscriptionSetting>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  final logger = ref.watch(loggingServiceProvider);

  final notifier = ChannelListNotifier(ref, settingsService, logger, []);

  notifier.loadInitialState();

  return notifier;
}, name: 'channelListProvider');

class ChannelListNotifier extends StateNotifier<List<ChannelSubscriptionSetting>> {
  final Ref _ref;
  final ISettingsService _settingsService;
  final ILoggingService _logger;

  ChannelListNotifier(this._ref, this._settingsService, this._logger, List<ChannelSubscriptionSetting> initialState) : super(initialState);

  Future<void> loadInitialState() async {
    _logger.info("ChannelListNotifier: Loading initial state...");
    try {
      final loadedState = await _settingsService.getChannelSubscriptions();
      if (state.length != loadedState.length || state != loadedState) {
        state = loadedState;
        _logger.info("ChannelListNotifier: Loaded ${state.length} channels.");
      } else {
        _logger.info("ChannelListNotifier: Loaded state matches initial state.");
      }
    } catch (e, s) {
      _logger.error("ChannelListNotifier: Error loading initial state", e, s);
      state = [];
    }
  }

  Future<void> reloadState() async {
    _logger.info("ChannelListNotifier: Reloading state from storage...");
    await _reloadFromStorage(isInitialLoad: false);
  }

  Future<void> _reloadFromStorage({required bool isInitialLoad}) async {
    try {
      final loadedState = await _settingsService.getChannelSubscriptions();
      if (!mounted) return;

      final currentStateSet = Set.from(state.map((e) => e.channelId));
      final loadedStateSet = Set.from(loadedState.map((e) => e.channelId));

      bool changed = currentStateSet.length != loadedStateSet.length || !currentStateSet.containsAll(loadedStateSet);

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
        _logger.warning("ChannelListNotifier: State kept unchanged due to reload error.");
      }
    }
  }

  void addChannel(ChannelSubscriptionSetting channel) {
    if (state.any((existing) => existing.channelId == channel.channelId)) {
      _logger.warning("ChannelListNotifier: Channel ${channel.channelId} already exists, cannot add.");
      return;
    }
    _logger.debug("ChannelListNotifier: Adding channel ${channel.channelId}");
    state = [...state, channel];
    _saveState();
  }

  void removeChannel(String channelId) {
    _logger.debug("ChannelListNotifier: Removing channel $channelId");
    state = state.where((c) => c.channelId != channelId).toList();
    _saveState();
  }

  void updateChannelSettings(String channelId, {bool? newMedia, bool? mentions, bool? live, bool? updates, bool? membersOnly, bool? clips}) {
    _logger.info(
      "ChannelListNotifier: Updating settings for $channelId (New:$newMedia, Mention:$mentions, Live:$live, Update:$updates, Members:$membersOnly, Clips:$clips)",
    );

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
    _saveState();
  }

  void reorderChannels(int oldIndex, int newIndex) {
    _logger.debug("ChannelListNotifier: Reordering from $oldIndex to $newIndex");
    if (oldIndex < 0 || oldIndex >= state.length) return;
    if (newIndex < 0 || newIndex > state.length) return;

    final item = state[oldIndex];
    final newState = List<ChannelSubscriptionSetting>.from(state);
    newState.removeAt(oldIndex);

    final adjustedNewIndex = (oldIndex < newIndex) ? newIndex - 1 : newIndex;
    final finalIndex = adjustedNewIndex.clamp(0, newState.length);

    newState.insert(finalIndex, item);

    state = newState;
    _saveState();
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
        channel.copyWith(
          notifyNewMedia: globalNewMedia,
          notifyMentions: globalMentions,
          notifyLive: globalLive,
          notifyUpdates: globalUpdate,
          notifyMembersOnly: globalMembersOnly,
          notifyClips: globalClips,
        ),
    ];
    _saveState();
  }

  Future<void> _saveState() async {
    _logger.info("ChannelListNotifier: Saving state (${state.length} channels)...");
    try {
      await _settingsService.saveChannelSubscriptions(state);
      _logger.info("ChannelListNotifier: State saved successfully.");
    } catch (e, s) {
      _logger.error("ChannelListNotifier: Error saving state", e, s);
    }
  }
}

class ApiKeyRequiredException implements Exception {
  final String message;
  ApiKeyRequiredException([this.message = 'API Key is required for this operation.']);
  @override
  String toString() => message;
}

final debouncedChannelSearchProvider = FutureProvider.autoDispose<List<Channel>>(
  (ref) async {
    final query = ref.watch(channelSearchQueryProvider);
    final apiKeyAsyncValue = ref.watch(apiKeyProvider);
    final apiService = ref.watch(apiServiceProvider);
    final logger = ref.watch(loggingServiceProvider);

    final String? apiKey = apiKeyAsyncValue.valueOrNull;

    logger.debug(
      '[Debounced Search] Triggered. Query: "$query", API Key State: isLoading=${apiKeyAsyncValue.isLoading}, hasError=${apiKeyAsyncValue.hasError}, Key Set: ${apiKey != null && apiKey.isNotEmpty}',
    );

    if (apiKeyAsyncValue.isLoading) {
      logger.debug('[Debounced Search] API Key is loading. Returning empty list for now.');
      return [];
    }
    if (apiKeyAsyncValue.hasError) {
      logger.error('[Debounced Search] API Key provider has error: ${apiKeyAsyncValue.error}. Throwing exception.');
      throw ApiKeyRequiredException('Failed to load API Key setting. Please check Settings.');
    }

    if (apiKey == null || apiKey.isEmpty) {
      logger.warning('[Debounced Search] API Key missing or empty. Throwing ApiKeyRequiredException.');
      throw ApiKeyRequiredException('Please enter your Holodex API Key in the settings first.');
    }

    if (query.length < 3) {
      logger.debug('[Debounced Search] Query too short ("$query"). Returning empty list.');
      return [];
    }

    logger.debug('[Debounced Search] Debouncing for 1000ms...');
    await Future.delayed(const Duration(milliseconds: 1000));
    logger.debug('[Debounced Search] Debounce finished.');

    final currentQuery = ref.read(channelSearchQueryProvider);
    if (query != currentQuery) {
      logger.debug(
        '[Debounced Search] Stale query detected ("$query" vs "$currentQuery"). Proceeding with old query result (will be replaced by new one soon).',
      );
    }

    if (currentQuery.length < 3) {
      logger.debug('[Debounced Search] Query became too short after debounce ("$currentQuery"). Returning empty list.');
      return [];
    }

    final currentApiKeyAsyncValue = ref.read(apiKeyProvider);
    final currentApiKey = currentApiKeyAsyncValue.valueOrNull;

    if (currentApiKey == null || currentApiKey.isEmpty) {
      logger.warning('[Debounced Search] API Key missing or empty after debounce. Throwing ApiKeyRequiredException.');
      throw ApiKeyRequiredException('Please enter your Holodex API Key in the settings first.');
    }

    logger.info('[Debounced Search] Executing search for channel: "$currentQuery"');
    try {
      final results = await apiService.searchChannels(currentQuery);
      logger.info('[Debounced Search] Found ${results.length} channels for "$currentQuery".');
      return results;
    } catch (e, s) {
      logger.error('[Debounced Search] Error searching channels for "$currentQuery"', e, s);
      rethrow;
    }
  },
  dependencies: [channelSearchQueryProvider, apiKeyProvider, apiServiceProvider, loggingServiceProvider],
  name: 'debouncedChannelSearchProvider',
);

final channelSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final channelNameProvider = FutureProvider.family<String?, String>((ref, channelId) async {
  if (channelId.isEmpty) return null;

  final cacheService = ref.watch(cacheServiceProvider);
  final name = await cacheService.getChannelName(channelId);

  return name;
}, name: 'channelNameProvider');
