import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/ui/widgets/channel_management_card.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class ChannelsPage extends HookConsumerWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(loggingServiceProvider);
    final bgService = FlutterBackgroundService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final manualPollTriggeredAt = useState<DateTime?>(null);
    final channelListNotifier = ref.read(channelListProvider.notifier);

    final statusAsync = ref.watch(backgroundServiceStatusStreamProvider);
    useEffect(() {
      if (manualPollTriggeredAt.value == null) {
        return null;
      }

      statusAsync.whenData((status) {
        final lastPoll = status.lastPollTime;
        final triggerTime = manualPollTriggeredAt.value;

        if (lastPoll != null && triggerTime != null && lastPoll.isAfter(triggerTime)) {
          logger.info("[ChannelsPage Effect] Detected poll completion after manual trigger. Reloading channel state...");
          channelListNotifier.reloadState();
          manualPollTriggeredAt.value = null;
        }
      });
      return null;
    }, [statusAsync, manualPollTriggeredAt.value]);

    return RefreshIndicator(
      onRefresh: () async {
        logger.info("ChannelsPage: Pull-to-refresh triggered.");
        await channelListNotifier.reloadState();

        final isRunning = await bgService.isRunning();
        if (isRunning) {
          logger.info("ChannelsPage: Invoking manual poll from refresh and recording trigger time...");
          final triggerTime = DateTime.now();
          manualPollTriggeredAt.value = triggerTime;
          bgService.invoke('triggerPoll');
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Manual poll triggered...'), duration: Duration(seconds: 2)));
        } else {
          logger.warning("ChannelsPage: Background service not running, manual poll not triggered from refresh.");
        }
        logger.info("ChannelsPage: Refresh action completed (UI part). Waiting for poll completion via listener.");
      },
      child: ListView(padding: const EdgeInsets.all(16.0), children: const [ChannelManagementCard()]),
    );
  }
}
