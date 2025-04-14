// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\application\state\background_service_state.dart
import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/main.dart'; // For service providers

// --- BackgroundStatus Data class ---
class BackgroundStatus {
  final bool isRunning;
  final DateTime? lastPollTime;
  final String? lastError; // Error message from the background process

  BackgroundStatus({required this.isRunning, this.lastPollTime, this.lastError});
}

// --- Provider for Last Background Error ---
// Kept in channel_providers.dart for now as background poller writes to it
// Moved it here to keep all background state together. Update channel_providers.dart to remove it.
final backgroundLastErrorProvider = StateProvider<String?>((ref) => null);

// --- StreamProvider for Background Status ---
final backgroundServiceStatusStreamProvider = StreamProvider.autoDispose<BackgroundStatus>((ref) {
  final backgroundService = ref.watch(backgroundServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  final logger = ref.watch(loggingServiceProvider);
  Timer? timer;
  final controller = StreamController<BackgroundStatus>();

  Future<void> fetchStatus() async {
    // Check if the provider is still active before fetching
    if (controller.isClosed) return;

    try {
      final isRunning = await backgroundService.isRunning();
      final lastPoll = await settingsService.getLastPollTime();
      // Read last error state from its provider
      final lastError = ref.read(backgroundLastErrorProvider);
      logger.debug("[StatusStream] Background Status Check: Running=$isRunning, LastPoll=$lastPoll, Error=$lastError");

      // Check again before adding to the controller
      if (!controller.isClosed) {
        controller.add(BackgroundStatus(isRunning: isRunning, lastPollTime: lastPoll, lastError: lastError));
      }
    } catch (e, s) {
      logger.error("[StatusStream] Error fetching background status", e, s);
      // Check again before adding error
      if (!controller.isClosed) {
        controller.addError(e, s); // Propagate error to the stream consumer
      }
    }
  }

  // Fetch immediately on creation
  fetchStatus();

  // Fetch periodically
  timer = Timer.periodic(const Duration(seconds: 15), (_) => fetchStatus()); // Check more frequently?

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
    logger.info("[StatusStream] Disposed background status stream.");
  });

  return controller.stream;
});
