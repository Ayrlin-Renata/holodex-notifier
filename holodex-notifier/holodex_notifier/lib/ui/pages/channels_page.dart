import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // {{ Import flutter_hooks }}
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart'; // {{ Import status provider }}
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/ui/widgets/channel_management_card.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

// {{ Change to HookConsumerWidget }}
class ChannelsPage extends HookConsumerWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(loggingServiceProvider);
    final bgService = FlutterBackgroundService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // {{ State to store the time when a manual poll was triggered }}
    final manualPollTriggeredAt = useState<DateTime?>(null);
    // {{ Access channel list notifier instance }}
    final channelListNotifier = ref.read(channelListProvider.notifier);


    // {{ Effect to react to poll completion }}
    final statusAsync = ref.watch(backgroundServiceStatusStreamProvider);
    useEffect(() {
      // Check if a manual poll was triggered and hasn't been processed yet
      if (manualPollTriggeredAt.value == null) {
        return null; // No active poll to wait for
      }

      // Process status updates
      statusAsync.whenData((status) {
        final lastPoll = status.lastPollTime;
        final triggerTime = manualPollTriggeredAt.value;

        // Check if poll completed *after* our trigger
        if (lastPoll != null && triggerTime != null && lastPoll.isAfter(triggerTime)) {
          logger.info("[ChannelsPage Effect] Detected poll completion after manual trigger. Reloading channel state...");
          // Reload the channel state from storage
          channelListNotifier.reloadState();
          // Reset the trigger time so we don't reload again for the same poll
          manualPollTriggeredAt.value = null;
        }
      });
      return null; // No cleanup needed specifically for this effect logic
    }, [statusAsync, manualPollTriggeredAt.value]); // Depend on stream and trigger time

    return RefreshIndicator(
      onRefresh: () async {
        logger.info("ChannelsPage: Pull-to-refresh triggered.");
        // Immediately reload state from storage (in case changes happened earlier)
        await channelListNotifier.reloadState();

        // Trigger manual poll and record time
        final isRunning = await bgService.isRunning();
        if (isRunning) {
          logger.info("ChannelsPage: Invoking manual poll from refresh and recording trigger time...");
          final triggerTime = DateTime.now(); // Record time *before* invoking
          manualPollTriggeredAt.value = triggerTime; // Store the trigger time
          bgService.invoke('triggerPoll');
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Manual poll triggered...'), duration: Duration(seconds: 2)));
        } else {
          logger.warning("ChannelsPage: Background service not running, manual poll not triggered from refresh.");
        }
        // The refresh indicator completes immediately; the effect handles the reload later.
        logger.info("ChannelsPage: Refresh action completed (UI part). Waiting for poll completion via listener.");
      },
      // The content of the page
      child: ListView(padding: const EdgeInsets.all(16.0), children: const [ChannelManagementCard()]),
    );
  }
}
