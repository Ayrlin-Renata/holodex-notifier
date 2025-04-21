import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/ui/widgets/channel_management_card.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class ChannelsPage extends HookConsumerWidget {
  ChannelsPage({super.key});
  static const String _infoCardFeatureKey = 'channelsPageInfoCardSeen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(loggingServiceProvider);
    final theme = Theme.of(context);
    final bgService = FlutterBackgroundService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final manualPollTriggeredAt = useState<DateTime?>(null);
    final channelListNotifier = ref.read(channelListProvider.notifier);

    final isFirstLaunchAsync = ref.watch(isFirstLaunchProvider);
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
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const ChannelManagementCard(),
          isFirstLaunchAsync.when(
            data: (seenValue) {
              final bool shouldShowInfo = !seenValue;

              if (shouldShowInfo) {
                return _buildFirstInstallInfo(context, ref, shouldShowInfo);
              } else {
                return const SizedBox.shrink();
              }
            },
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
            error:
                (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: Text('Error loading setting: $error', style: TextStyle(color: theme.colorScheme.error))),
                ),
          ),
        ],
      ),
    );
  }

  final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
    final settings = ref.watch(settingsServiceProvider);
    return await settings.getFeatureSeen(_infoCardFeatureKey);
  });

  Widget _buildFirstInstallInfo(BuildContext context, WidgetRef ref, bool isActuallyFirstLaunch) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Text('Pull down to refresh!', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Once you\'ve added some channels, pull down to refresh!\n\n'
              'We\'ll immediately grab new info, and there might be a small barrage of notifications, ehe.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),

            if (isActuallyFirstLaunch)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: Text('Dismiss', style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
                  onPressed: () async {
                    await ref.read(settingsServiceProvider).setFeatureSeen(_infoCardFeatureKey);
                    ref.invalidate(isFirstLaunchProvider);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
