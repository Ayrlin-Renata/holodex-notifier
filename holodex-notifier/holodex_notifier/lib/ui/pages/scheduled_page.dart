import 'package:flutter/material.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/ui/widgets/scheduled_notifications_card.dart'; // Import the refactored card content
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart'; // {{ Import moved provider }}
import 'package:holodex_notifier/main.dart'; // Import loggingServiceProvider
import 'package:flutter_background_service/flutter_background_service.dart'; // {{ Import background service }}
import 'package:holodex_notifier/application/state/settings_providers.dart'; // For isFirstLaunch etc.

// This page displays the scheduled notifications and supports pull-to-refresh.
class ScheduledPage extends ConsumerWidget {
  const ScheduledPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(loggingServiceProvider);
    final bgService = FlutterBackgroundService(); // {{ Get service instance }}
    final scaffoldMessenger = ScaffoldMessenger.of(context); // {{ Get ScaffoldMessenger }}
    final apiKeyAsync = ref.watch(apiKeyProvider);
    final isFirstLaunchAsync = ref.watch(isFirstLaunchProvider);

    return RefreshIndicator(
      onRefresh: () async {
        logger.info("ScheduledPage: Pull-to-refresh triggered.");
        final scheduledRefreshFuture = ref.read(scheduledNotificationsProvider.notifier).fetchScheduledNotifications(isRefreshing: true);

        // Check if service is running before invoking
        // Read the stream provider's latest value if available, otherwise check service directly
        // Reading the .future isn't ideal here as it would wait. Let's check isRunning directly for polling trigger.
        final isBgRunning = await bgService.isRunning();
        if (isBgRunning) {
          logger.info("ScheduledPage: Invoking manual poll from refresh...");
          bgService.invoke('triggerPoll');
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Manual poll triggered...'), duration: Duration(seconds: 2)));
        } else {
          logger.warning("ScheduledPage: Background service not running, manual poll not triggered from refresh.");
        }

        await scheduledRefreshFuture;
        logger.info("ScheduledPage: Refresh action completed.");
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          isFirstLaunchAsync.when(
            data: (isFirstLaunchValue) {
              final bool shouldShowInfo =
                  isFirstLaunchValue || (apiKeyAsync.hasValue && (apiKeyAsync.valueOrNull == null || apiKeyAsync.valueOrNull!.isEmpty));

              if (shouldShowInfo) {
                return _buildFirstInstallInfo(context, ref, isFirstLaunchValue);
              } else {
                return const SizedBox.shrink(); // Don't show anything if conditions aren't met
              }
            },
            // Show simple loading/error indicators for the first launch flag
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
            error:
                (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: Text('Error loading setting: $error', style: TextStyle(color: Theme.of(context).colorScheme.error))),
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
            // {{ Use the passed bool here }}
            if (isActuallyFirstLaunch)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: Text('Dismiss', style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
                  onPressed: () async {
                    await ref.read(settingsServiceProvider).setIsFirstLaunch(false);
                    // ignore: unused_result
                    ref.refresh(isFirstLaunchProvider); // Refresh provider to hide notice
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
    final theme = Theme.of(context);
    final subscribedChannels = ref.watch(channelListProvider); // Get list of subscribed channels
    final selectedTypes = ref.watch(scheduledFilterTypeProvider);
    final selectedChannelId = ref.watch(scheduledFilterChannelProvider);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface, // Slightly different background
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Scheduled Items', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            // Type Filters
            Wrap(
              spacing: 8.0,
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
           // Channel Filter
            if (subscribedChannels.isNotEmpty) ...[
              const SizedBox(height: 8),
              // {{ Change DropdownButton type to String? }}
              DropdownButton<String?>(
                isExpanded: true,
                // {{ Value is now String? }}
                value: selectedChannelId, // This assignment is now correct
                hint: const Text('All Channels'),
                underline: Container(height: 1, color: theme.dividerColor),
                items: [
                  // "All Channels" option maps to null
                  // {{ Change DropdownMenuItem type to String? }}
                  const DropdownMenuItem<String?>(
                    value: null, // Correct type
                    child: Text('All Channels'),
                  ),
                  // Individual channels map to their ID string
                  ...subscribedChannels.map((channel) {
                    // {{ Change DropdownMenuItem type to String? }}
                    return DropdownMenuItem<String?>(
                      // {{ Value is now the channelId String }}
                      value: channel.channelId, // Correct type
                      child: Text(channel.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ],
                onChanged: (String? newValue) {
                  // {{ Update the String? provider }}
                  ref.read(scheduledFilterChannelProvider.notifier).state = newValue; // This assignment is now correct
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 4. Provider definition remains the same
final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsServiceProvider);
  return await settings.getIsFirstLaunch();
});
