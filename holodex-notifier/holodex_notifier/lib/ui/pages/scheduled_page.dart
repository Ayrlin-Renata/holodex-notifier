// ... Other imports ...
import 'dart:async'; // {{ Add import for unawaited }}
import 'package:flutter/scheduler.dart'; // Needed for timeDilation

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Import flutter_hooks
import 'package:holodex_notifier/application/state/background_service_state.dart'; // Import status provider
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/ui/widgets/scheduled_notifications_card.dart'; // Import the refactored card content
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart'; // {{ Import moved provider }}
import 'package:holodex_notifier/main.dart'; // Import loggingServiceProvider
import 'package:flutter_background_service/flutter_background_service.dart'; // {{ Import background service }}
import 'package:holodex_notifier/application/state/settings_providers.dart'; // For isFirstLaunch etc.

// {{ Modify ScheduledPage to accept PageController }}
class ScheduledPage extends HookConsumerWidget {
  // {{ Add PageController parameter }}
  final PageController pageController;
  const ScheduledPage({super.key, required this.pageController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(loggingServiceProvider);
    final bgService = FlutterBackgroundService(); // {{ Get service instance }}
    final scaffoldMessenger = ScaffoldMessenger.of(context); // {{ Get ScaffoldMessenger }}
    final apiKeyAsync = ref.watch(apiKeyProvider);
    final isFirstLaunchAsync = ref.watch(isFirstLaunchProvider);

    // {{ State to store the time when a manual poll was triggered }}
    final manualPollTriggeredAt = useState<DateTime?>(null);
    // {{ Access scheduled notifications notifier instance }}
    final scheduledNotifier = ref.read(scheduledNotificationsProvider.notifier);
    final statusAsync = ref.watch(backgroundServiceStatusStreamProvider);


    // {{ Modified Effect to react to poll completion }}
    useEffect(() {
      // Check if a manual poll was triggered and hasn't been processed yet
      if (manualPollTriggeredAt.value == null) {
        logger.trace("[ScheduledPage Effect] No active manual poll trigger time set. Skipping status check.");
        return null; // No active poll to wait for
      }

      // Process status updates when data arrives
      statusAsync.whenData((status) {
        logger.trace("[ScheduledPage Effect] Received status update. LastPoll=${status.lastPollTime}, TriggerTime=${manualPollTriggeredAt.value}");
        final lastPoll = status.lastPollTime;
        final triggerTime = manualPollTriggeredAt.value; // Capture the trigger time we're checking against

        // {{ Check triggerTime again inside callback }}
        // Check if poll completed *after* our trigger AND the trigger hasn't been reset yet
        if (triggerTime != null && lastPoll != null && lastPoll.isAfter(triggerTime)) {
          logger.info("[ScheduledPage Effect] Detected poll completion after manual trigger. Scheduling refresh and reset for post-frame.");

          // {{ Defer the fetch and reset }}
          // Schedule the refresh and reset *after* the current build frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Re-check the state inside the callback to ensure it hasn't changed unexpectedly
            if (manualPollTriggeredAt.value == triggerTime) { // Check if it's still the same trigger
              logger.trace("[ScheduledPage Effect - PostFrame] Refreshing scheduled notifications...");
              // Don't await inside the post-frame callback. Let the notifier handle its state.
              unawaited(scheduledNotifier.fetchScheduledNotifications(isRefreshing: true));

              logger.trace("[ScheduledPage Effect - PostFrame] Resetting trigger time...");
              manualPollTriggeredAt.value = null; // Reset the trigger AFTER initiating the fetch
            } else {
              logger.trace("[ScheduledPage Effect - PostFrame] Trigger time changed before post-frame callback executed. Skipping refresh/reset.");
            }
          });
        } else {
           logger.trace("[ScheduledPage Effect] Poll completion not detected or trigger time missing/stale.");
        }
      });
      // Return null for cleanup function as it's not needed here
      return null;
      // Ensure the effect re-runs if the status stream or the trigger time changes
    }, [statusAsync, manualPollTriggeredAt.value]); // {{ Keep dependencies the same }}

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        // ... refresh logic ...
      },
      // {{ REMOVE GestureDetector - Reverting to original ListView structure }}
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          isFirstLaunchAsync.when(
            data: (isFirstLaunchValue) {
              final bool shouldShowInfo = isFirstLaunchValue;

              if (shouldShowInfo) {
                return _buildFirstInstallInfo(context, ref, isFirstLaunchValue);
              } else {
                return const SizedBox.shrink(); // Don't show anything if conditions aren't met
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

 // ... existing _buildFirstInstallInfo and _buildFilterSection methods ...
 // Keep the existing helper methods unchanged
  Widget _buildFirstInstallInfo(BuildContext context, WidgetRef ref, bool isActuallyFirstLaunch) {
    // ... existing code ...
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
            // {{ Use the passed bool here }}
            if (isActuallyFirstLaunch)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: Text('Dismiss', style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
                  onPressed: () async {
                    // {{ Persist the setting change }}
                    await ref.read(settingsServiceProvider).setIsFirstLaunch(false);
                    ref.invalidate(isFirstLaunchProvider); // Use invalidate to force re-fetch
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Filter UI Builder
  Widget _buildFilterSection(BuildContext context, WidgetRef ref) {
    // ... existing code ...
    final theme = Theme.of(context);
    final subscribedChannels = ref.watch(channelListProvider); // Get list of subscribed channels
    final selectedTypes = ref.watch(scheduledFilterTypeProvider);
    final selectedChannelId = ref.watch(scheduledFilterChannelProvider);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface, // Slightly different background
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(0.0), // Adjusted padding for filter card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding( // Padding specifically for the title
              padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 4.0),
              child: Text('Filter Scheduled Items', style: theme.textTheme.labelLarge),
            ),
            // Type Filters
            Padding( // Padding for the chips
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0, // Added run spacing
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
            // Channel Filter
            if (subscribedChannels.isNotEmpty) ...[
              // No extra SizedBox needed if padding is handled below
              Padding( // Padding for the dropdown
                padding: const EdgeInsets.symmetric(horizontal: 12.0).copyWith(bottom: 8.0, top: 4.0), // More padding for dropdown
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: selectedChannelId,
                  hint: const Text('All Channels'),
                  underline: Container(height: 1, color: theme.dividerColor),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Channels'),
                    ),
                    ...subscribedChannels.map((channel) {
                      return DropdownMenuItem<String?>(
                        value: channel.channelId,
                        child: Text(channel.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? newValue) {
                    ref.read(scheduledFilterChannelProvider.notifier).state = newValue;
                  },
                ),
              ),
            ],
            // Add padding if there are no channels to maintain consistent spacing
            if (subscribedChannels.isEmpty) const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}

// Provider definition remains the same
final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsServiceProvider);
  return await settings.getIsFirstLaunch();
});