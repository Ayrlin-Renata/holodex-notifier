import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/main.dart';

class BackgroundStatus {
  final bool isRunning;
  final DateTime? lastPollTime;
  final String? lastError;

  BackgroundStatus({required this.isRunning, this.lastPollTime, this.lastError});
}

final backgroundLastErrorProvider = StateProvider<String?>((ref) => null);

final backgroundServiceStatusStreamProvider = StreamProvider.autoDispose<BackgroundStatus>((ref) {
  final backgroundService = ref.watch(backgroundServiceProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  final logger = ref.watch(loggingServiceProvider);
  Timer? timer;
  final controller = StreamController<BackgroundStatus>();

  Future<void> fetchStatus() async {
    if (controller.isClosed) return;

    try {
      final isRunning = await backgroundService.isRunning();
      final lastPoll = await settingsService.getLastPollTime();
      final lastError = ref.read(backgroundLastErrorProvider);
      logger.debug("Background status: isRunning=$isRunning, lastPoll=$lastPoll, lastError=$lastError");

      if (!controller.isClosed) {
        controller.add(BackgroundStatus(isRunning: isRunning, lastPollTime: lastPoll, lastError: lastError));
      }
    } catch (e, s) {
      logger.error("Error fetching background status", e, s);
      if (!controller.isClosed) {
        controller.addError(e, s);
      }
    }
  }

  fetchStatus();

  timer = Timer.periodic(const Duration(seconds: 15), (_) => fetchStatus());

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
    logger.info("[StatusStream] Disposed background status stream.");
  });

  return controller.stream;
});
