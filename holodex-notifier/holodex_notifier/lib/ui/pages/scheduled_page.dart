import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/ui/widgets/scheduled_notifications_card.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:holodex_notifier/main.dart';

class ScheduledPage extends HookConsumerWidget {
  final PageController pageController;
  const ScheduledPage({super.key, required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(loggingServiceProvider);
    final isFirstLaunchAsync = ref.watch(isFirstLaunchProvider);

    final manualPollTriggeredAt = useState<DateTime?>(null);

    final scheduledNotifier = ref.read(scheduledNotificationsProvider.notifier);
    final statusAsync = ref.watch(backgroundServiceStatusStreamProvider);

    useEffect(() {
      if (manualPollTriggeredAt.value == null) {
        logger.trace("[ScheduledPage Effect] No active manual poll trigger time set. Skipping status check.");
        return null;
      }

      statusAsync.whenData((status) {
        logger.trace("[ScheduledPage Effect] Received status update. LastPoll=${status.lastPollTime}, TriggerTime=${manualPollTriggeredAt.value}");
        final lastPoll = status.lastPollTime;
        final triggerTime = manualPollTriggeredAt.value;

        if (triggerTime != null && lastPoll != null && lastPoll.isAfter(triggerTime)) {
          logger.info("[ScheduledPage Effect] Detected poll completion after manual trigger. Scheduling refresh and reset for post-frame.");

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (manualPollTriggeredAt.value == triggerTime) {
              logger.trace("[ScheduledPage Effect - PostFrame] Refreshing scheduled notifications...");

              unawaited(scheduledNotifier.fetchScheduledNotifications(isRefreshing: true));

              logger.trace("[ScheduledPage Effect - PostFrame] Resetting trigger time...");
              manualPollTriggeredAt.value = null;
            } else {
              logger.trace("[ScheduledPage Effect - PostFrame] Trigger time changed before post-frame callback executed. Skipping refresh/reset.");
            }
          });
        } else {
          logger.trace("[ScheduledPage Effect] Poll completion not detected or trigger time missing/stale.");
        }
      });

      return null;
    }, [statusAsync, manualPollTriggeredAt.value]);

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          isFirstLaunchAsync.when(
            data: (isFirstLaunchValue) {
              final bool shouldShowInfo = isFirstLaunchValue;

              if (shouldShowInfo) {
                return _buildFirstInstallInfo(context, ref, isFirstLaunchValue);
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
          _buildFilterSection(context, ref),
          const SizedBox(height: 8),
          const ScheduledNotificationsCard(),
        ],
      ),
    );
  }

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
                Text('Welcome to Holodex Notifier!', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Start getting notified by adding channels!\n\n'
              'You\'ll need a Holodex API key first, but we\'ve got you covered in Settings.\n\n'
              'Swipe left to get started!',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onTertiaryContainer),
            ),

            if (isActuallyFirstLaunch)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: Text('Dismiss', style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
                  onPressed: () async {
                    await ref.read(settingsServiceProvider).setIsFirstLaunch(false);
                    ref.invalidate(isFirstLaunchProvider);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscribedChannels = ref.watch(channelListProvider);
    final selectedTypes = ref.watch(scheduledFilterTypeProvider);
    final selectedChannelId = ref.watch(scheduledFilterChannelProvider);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 4.0),
              child: Text('Filter Scheduled Items', style: theme.textTheme.labelLarge),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  FilterChip(
                    label: const Text('Live'),
                    selected: selectedTypes.contains(NotificationEventType.live),
                    onSelected: (selected) {
                      final currentTypes = ref.read(scheduledFilterTypeProvider);
                      if (selected) {
                        ref.read(scheduledFilterTypeProvider.notifier).state = {...currentTypes, NotificationEventType.live};
                      } else {
                        ref.read(scheduledFilterTypeProvider.notifier).state = currentTypes.difference({NotificationEventType.live});
                      }
                    },
                  ),
                  FilterChip(
                    label: const Text('Reminders'),
                    selected: selectedTypes.contains(NotificationEventType.reminder),
                    onSelected: (selected) {
                      final currentTypes = ref.read(scheduledFilterTypeProvider);
                      if (selected) {
                        ref.read(scheduledFilterTypeProvider.notifier).state = {...currentTypes, NotificationEventType.reminder};
                      } else {
                        ref.read(scheduledFilterTypeProvider.notifier).state = currentTypes.difference({NotificationEventType.reminder});
                      }
                    },
                  ),
                ],
              ),
            ),

            if (subscribedChannels.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0).copyWith(bottom: 8.0, top: 4.0),
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: selectedChannelId,
                  hint: const Text('All Channels'),
                  underline: Container(height: 1, color: theme.dividerColor),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Channels')),
                    ...subscribedChannels.map((channel) {
                      return DropdownMenuItem<String?>(value: channel.channelId, child: Text(channel.name, overflow: TextOverflow.ellipsis));
                    }),
                  ],
                  onChanged: (String? newValue) {
                    ref.read(scheduledFilterChannelProvider.notifier).state = newValue;
                  },
                ),
              ),
            ],

            if (subscribedChannels.isEmpty) const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}

final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsServiceProvider);
  return await settings.getIsFirstLaunch();
});
