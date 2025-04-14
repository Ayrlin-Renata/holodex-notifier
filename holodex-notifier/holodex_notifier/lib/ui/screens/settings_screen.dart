import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/ui/widgets/app_behavior_settings_card.dart';
import 'package:holodex_notifier/ui/widgets/channel_management_card.dart';
import 'package:holodex_notifier/ui/widgets/scheduled_notifications_card.dart';
import 'package:holodex_notifier/ui/widgets/background_status_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import interface

class ScheduledNotificationsNotifier extends StateNotifier<AsyncValue<List<CachedVideo>>> {
  final ICacheService _cacheService;
  final ILoggingService _logger;
  bool _isFetching = false; // Basic lock to prevent concurrent fetches

  ScheduledNotificationsNotifier(this._cacheService, this._logger) : super(const AsyncValue.loading()) {
    // Load initial data when the notifier is created
    fetchScheduledNotifications();
  }

  Future<void> fetchScheduledNotifications({bool isRefreshing = false}) async {
    if (_isFetching && !isRefreshing) {
      _logger.debug("[ScheduledNotificationsNotifier] Fetch already in progress, skipping.");
      return;
    }
    _isFetching = true;
    _logger.info("[ScheduledNotificationsNotifier] Fetching scheduled notifications...");

    // Set loading state, keeping previous data if refreshing
    if (isRefreshing && state.hasValue) {
      state = AsyncLoading<List<CachedVideo>>().copyWithPrevious(state);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _cacheService.getScheduledVideos();
      if (mounted) {
        // Check if notifier is still mounted before setting state
        state = AsyncValue.data(data);
        _logger.info("[ScheduledNotificationsNotifier] Fetch successful, found ${data.length} items.");
      } else {
        _logger.info("[ScheduledNotificationsNotifier] Notifier unmounted after fetch, discarding data.");
      }
    } catch (e, s) {
      _logger.error("[ScheduledNotificationsNotifier] Error fetching scheduled notifications", e, s);
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    } finally {
      // Check mounted again before resetting lock, though less critical here
      if (mounted) {
        _isFetching = false;
      }
    }
  }
}

final scheduledNotificationsProvider = StateNotifierProvider.autoDispose<ScheduledNotificationsNotifier, AsyncValue<List<CachedVideo>>>((ref) {
  final log = ref.watch(loggingServiceProvider);
  log.info("Creating ScheduledNotificationsNotifier...");
  final cacheService = ref.watch(cacheServiceProvider);
  ref.onDispose(() => log.info("Disposed scheduled notifications notifier."));
  return ScheduledNotificationsNotifier(cacheService, log);
}, name: 'scheduledNotificationsProvider'); // Add name for clarity

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Logic to start the service if not running (remains the same) ---
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final logger = ref.read(loggingServiceProvider);
        final bgService = ref.read(backgroundServiceProvider); // Use the sync provider
        try {
          final bool running = await bgService.isRunning();
          logger.info("[SettingsScreen] Initial check: Background service running: $running");
          if (!running) {
            logger.info("[SettingsScreen] Service not running, attempting to start polling...");
            await bgService.startPolling();
            logger.info("[SettingsScreen] Start polling command issued.");
            // Refresh status after attempting start
            // ignore: unused_result
            ref.refresh(backgroundServiceStatusStreamProvider);
          }
        } catch (e, s) {
          logger.error("[SettingsScreen] Error checking or starting background service", e, s);
        }
      });
      return null; // No specific cleanup needed for this effect
    }, const []); // Runs once

    // --- Build the UI (Scaffold, ListView, Cards) ---
    return Scaffold(
      appBar: AppBar(title: const Text('Holodex Notifier Settings'), elevation: 1),
      body: RefreshIndicator(
        onRefresh: () async {
          // Manual refresh logic
          final logger = ref.read(loggingServiceProvider);
          logger.info("Pull-to-refresh triggered.");

          // Create a list of the Futures we need to wait for.
          final List<Future<void>> refreshFutures = [
            // Call reloadState on the channel list notifier
            ref.read(channelListProvider.notifier).reloadState(),

            // Call the fetch method on the scheduled notifications notifier
            // This method already returns a Future<void> implicitly or explicitly
            // because it's marked async.
            ref.read(scheduledNotificationsProvider.notifier).fetchScheduledNotifications(isRefreshing: true),
          ];

          // Wait for both asynchronous operations to complete.
          // Future.wait expects an Iterable<Future>, which refreshFutures now is.
          await Future.wait(refreshFutures);

          logger.info("Refresh complete.");
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
            AppBehaviorSettingsCard(),
            SizedBox(height: 16),
            ChannelManagementCard(),
            SizedBox(height: 16),
            ScheduledNotificationsCard(),
            SizedBox(height: 16),
            BackgroundStatusCard(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Data class for background status
class BackgroundStatus {
  final bool isRunning;
  final DateTime? lastPollTime;
  final String? lastError; // Now included here

  BackgroundStatus({required this.isRunning, this.lastPollTime, this.lastError});
}

// StreamProvider for Background Status
final backgroundServiceStatusStreamProvider = StreamProvider.autoDispose<BackgroundStatus>((ref) {
  final backgroundService = ref.watch(backgroundServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  Timer? timer;
  final controller = StreamController<BackgroundStatus>();

  Future<void> fetchStatus() async {
    try {
      final isRunning = await backgroundService.isRunning();
      final lastPoll = await settingsService.getLastPollTime();
      final lastError = ref.read(backgroundLastErrorProvider); // Read last error state
      print("Background Status Check: Running=$isRunning, LastPoll=$lastPoll, Error=$lastError");
      if (!controller.isClosed) {
        controller.add(BackgroundStatus(isRunning: isRunning, lastPollTime: lastPoll, lastError: lastError));
      }
    } catch (e, s) {
      print("Error fetching background status: $e\n$s"); // TODO: Use logger
      if (!controller.isClosed) {
        controller.addError(e, s); // Propagate error to the stream consumer
      }
    }
  }

  // Fetch immediately on creation
  fetchStatus();

  // Fetch periodically
  timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchStatus()); // Check every 30s

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
    print("Disposed background status stream.");
  });

  return controller.stream;
});

// Provider for Last Background Error
final backgroundLastErrorProvider = StateProvider<String?>((ref) => null);
