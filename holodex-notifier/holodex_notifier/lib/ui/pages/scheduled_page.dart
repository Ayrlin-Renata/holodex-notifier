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
      onRefresh: () async {
        // Add refresh logic if needed, e.g., fetch notifications
        logger.info("ScheduledPage: Pull-to-refresh triggered.");
        await scheduledNotifier.fetchScheduledNotifications(isRefreshing: true);
        // Manual poll trigger logic can remain if desired
        // ... (manual poll trigger logic) ...
      },
      child: Column(
        // Use Column for layout
        children: [
          Expanded(
            // Make the primary content scrollable
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
                const ScheduledNotificationsCard(), // Main card list
              ],
            ),
          ),
          // Dismissed items area at the bottom
          const DismissedNotificationsArea(),
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
    // Watch the state from the StateProvider
    final selectedTypes = ref.watch(scheduledFilterTypeProvider);
    final selectedChannelId = ref.watch(scheduledFilterChannelProvider);
    // Get SettingsService to save the state
    final settingsService = ref.watch(settingsServiceProvider);
    final logger = ref.watch(loggingServiceProvider);


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
                    onSelected: (selected) async { // Make callback async
                      final currentTypes = Set<NotificationEventType>.from(selectedTypes);
                      if (selected) {
                        currentTypes.add(NotificationEventType.live);
                      } else {
                        currentTypes.remove(NotificationEventType.live);
                      }
                      // 1. Update the state provider
                      ref.read(scheduledFilterTypeProvider.notifier).state = currentTypes;
                      // 2. Manually save the state
                      try {
                        await settingsService.setScheduledFilterTypes(currentTypes);
                        logger.debug("Saved scheduled filter types after UI toggle: ${currentTypes.map((e)=>e.name).join(',')}");
                      } catch (e,s) {
                         logger.error("Failed to save scheduled filter types from UI", e, s);
                         // Optionally show an error message to the user
                      }
                    },
                  ),
                  FilterChip(
                    label: const Text('Reminders'),
                    selected: selectedTypes.contains(NotificationEventType.reminder),
                    onSelected: (selected) async { // Make callback async
                      final currentTypes = Set<NotificationEventType>.from(selectedTypes);
                      if (selected) {
                         currentTypes.add(NotificationEventType.reminder);
                      } else {
                         currentTypes.remove(NotificationEventType.reminder);
                      }
                       // 1. Update the state provider
                       ref.read(scheduledFilterTypeProvider.notifier).state = currentTypes;
                       // 2. Manually save the state
                       try {
                        await settingsService.setScheduledFilterTypes(currentTypes);
                        logger.debug("Saved scheduled filter types after UI toggle: ${currentTypes.map((e)=>e.name).join(',')}");
                      } catch (e,s) {
                         logger.error("Failed to save scheduled filter types from UI", e, s);
                         // Optionally show an error message to the user
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

// NEW: Dismissed Notifications Area Widget
class DismissedNotificationsArea extends ConsumerWidget {
  const DismissedNotificationsArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dismissedItems = ref.watch(dismissedNotificationsProvider);
    final appController = ref.watch(appControllerProvider);

    if (dismissedItems.isEmpty) {
      return const SizedBox.shrink(); // Don't show if empty
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest, // Background color for the area
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: ExpansionTile(
        title: Text(
          'Dismissed Notifications (${dismissedItems.length})',
          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 8.0),
        initiallyExpanded: false, // Start collapsed
        children:
            dismissedItems.map((item) {
              return Card(
                elevation: 0.5,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    backgroundImage: item.videoData.channelAvatarUrl != null ? NetworkImage(item.videoData.channelAvatarUrl!) : null,
                    child: item.videoData.channelAvatarUrl == null ? const Icon(Icons.person_outline, size: 16) : null,
                  ),
                  title: Text(item.formattedTitle, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    item.formattedBody,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore_from_trash_outlined, color: Colors.green),
                    tooltip: 'Restore Notification',
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      appController.restoreScheduledNotification(item);
                      // Optional: Show a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Restored notification for "${item.videoData.videoTitle}"'), duration: const Duration(seconds: 2)),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}