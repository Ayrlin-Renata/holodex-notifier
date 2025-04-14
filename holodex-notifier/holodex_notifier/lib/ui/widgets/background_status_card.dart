import 'package:flutter/material.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
// Removed: import 'package:holodex_notifier/application/state/channel_providers.dart' hide backgroundLastErrorProvider; // Not needed here directly
import 'package:hooks_riverpod/hooks_riverpod.dart';
// For providers backgroundServiceStatusStreamProvider, backgroundLastErrorProvider
import 'package:holodex_notifier/application/state/settings_providers.dart'; // For pollFrequencyProvider
import 'package:holodex_notifier/main.dart'; // For backgroundServiceProvider, loggingServiceProvider
import 'package:intl/intl.dart'; // For date formatting
// REMOVED: import 'package:holodex_notifier/ui/widgets/settings_card.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // To invoke service

// No longer needs SettingsCard parent
class BackgroundStatusCard extends HookConsumerWidget {
  const BackgroundStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(backgroundServiceStatusStreamProvider);
    final pollFrequency = ref.watch(pollFrequencyProvider);

    final backgroundService = FlutterBackgroundService(); // Get instance to invoke
    final logger = ref.watch(loggingServiceProvider); // Get logger

    // REMOVED: SettingsCard(...) wrapper
    // Return the content Column directly based on the AsyncValue state
    return statusAsync.when(
      data: (status) {
        final nextPollTime = status.lastPollTime?.add(pollFrequency);
        final lastError = status.lastError; // Get error from status object

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // Adjusted padding

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Service Status', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
                    Chip(
                      label: Text(status.isRunning ? 'Running' : 'Stopped', style: theme.primaryTextTheme.labelLarge),
                      backgroundColor: status.isRunning ? theme.primaryColor : theme.colorScheme.error,
                      avatar: Icon(
                        status.isRunning ? Icons.check_circle : Icons.cancel,
                        color: status.isRunning ? theme.primaryTextTheme.bodyMedium!.color : theme.colorScheme.onError,
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Successful Poll: ${status.lastPollTime != null ? DateFormat.yMd().add_jm().format(status.lastPollTime!.toLocal()) : 'Never'}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Next Scheduled Poll: ${nextPollTime != null ? DateFormat.yMd().add_jm().format(nextPollTime.toLocal()) : 'N/A'}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                if (lastError != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last Error: $lastError',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.clear, size: 16, color: theme.colorScheme.onErrorContainer),
                          tooltip: 'Clear Error Message',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            ref.read(backgroundLastErrorProvider.notifier).state = null;
                            // Trigger a refresh of the status stream to update UI immediately
                            // ignore: unused_result
                            ref.refresh(backgroundServiceStatusStreamProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: const Text('Poll Now'),
                    onPressed:
                        !status
                                .isRunning // Disable if service isn't running
                            ? null
                            : () {
                              // Trigger the background service to poll immediately
                              logger.info("Invoking manual poll...");
                              backgroundService.invoke('triggerPoll');
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Manual poll triggered...'), duration: Duration(seconds: 2)));

                              // Refresh the status stream immediately to show "polling" state sooner
                              // ignore: unused_result
                              ref.refresh(backgroundServiceStatusStreamProvider);

                              // Refresh data providers after a short delay allowing poll to start processing
                              Future.delayed(const Duration(seconds: 3), () {
                                if (context.mounted) {
                                  logger.debug("Refreshing status/scheduled/channels after 3s delay post manual poll trigger.");
                                  // ignore: unused_result
                                  ref.refresh(backgroundServiceStatusStreamProvider);
                                  ref.read(scheduledNotificationsProvider.notifier).fetchScheduledNotifications(isRefreshing: true);
                                  ref.read(channelListProvider.notifier).reloadState(); // Refresh channel list too
                                }
                              });
                            },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
      error:
          (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading background status: $error', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ),
    );
  }
}
