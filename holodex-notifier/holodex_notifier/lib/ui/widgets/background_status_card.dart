import 'package:flutter/material.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart' hide backgroundLastErrorProvider;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/ui/screens/settings_screen.dart'; // For providers
import 'package:holodex_notifier/application/state/settings_providers.dart'; // For pollFrequencyProvider
import 'package:holodex_notifier/main.dart'; // For backgroundServiceProvider
import 'package:intl/intl.dart'; // For date formatting
import 'package:holodex_notifier/ui/widgets/settings_card.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // To invoke service

class BackgroundStatusCard extends HookConsumerWidget {
  const BackgroundStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(backgroundServiceStatusStreamProvider);
    final pollFrequency = ref.watch(pollFrequencyProvider);

    final backgroundService = FlutterBackgroundService(); // Get instance to invoke
    final logger = ref.watch(loggingServiceProvider); // Get logger

    return SettingsCard(
      title: 'Background Process Status',
      children: [
        statusAsync.when(
          data: (status) {
            final nextPollTime = status.lastPollTime?.add(pollFrequency);
            final lastError = status.lastError; // Get error from status object

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service Status:'),
                    Chip(
                      label: Text(status.isRunning ? 'Running' : 'Stopped'),
                      backgroundColor: status.isRunning ? Colors.green.shade100 : Colors.red.shade100,
                      avatar: Icon(
                        status.isRunning ? Icons.check_circle : Icons.cancel,
                        color: status.isRunning ? Colors.green : Colors.red,
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
                const SizedBox(height: 16),
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
                            // We might need to trigger a refresh of the status stream here
                            // or wait for the next automatic refresh.
                            // Let's manually refresh the stream for now:
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
                                .isRunning // Disable if service isn't running? Or let it try anyway?
                            ? null
                            : () {
                              // Trigger the background service to poll immediately
                              logger.info("Invoking manual poll...");
                              backgroundService.invoke('triggerPoll');
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Manual poll triggered...'), duration: Duration(seconds: 2)));

                              // --- ADD REFRESH ---
                            // Refresh immediately to signal the UI something happened
                            // ignore: unused_result
                            ref.refresh(backgroundServiceStatusStreamProvider);
                            logger.debug("Refreshed background status stream immediately after invoking poll.");

                            // Refresh at 1 second
                            Future.delayed(const Duration(seconds: 1), () {
                              if (context.mounted) {
                                logger.debug("Refreshing background status and scheduled notifications after 1s delay.");
                                // ignore: unused_result
                                ref.refresh(backgroundServiceStatusStreamProvider);
                                // ignore: unused_result
                                ref.refresh(scheduledNotificationsProvider);
                                ref.read(channelListProvider.notifier).reloadState();
                              } else {
                                logger.debug("Widget unmounted, skipping 1s delayed refresh.");
                              }
                            });

                            // Refresh at 3 seconds
                            Future.delayed(const Duration(seconds: 3), () {
                              if (context.mounted) {
                                logger.debug("Refreshing background status and scheduled notifications after 3s delay.");
                                // ignore: unused_result
                                ref.refresh(backgroundServiceStatusStreamProvider);
                                // ignore: unused_result
                                ref.refresh(scheduledNotificationsProvider);
                                ref.read(channelListProvider.notifier).reloadState();
                              } else {
                                logger.debug("Widget unmounted, skipping 3s delayed refresh.");
                              }
                            });

                            // Refresh at 6 seconds
                            Future.delayed(const Duration(seconds: 6), () {
                              if (context.mounted) {
                                logger.debug("Refreshing background status and scheduled notifications after 6s delay.");
                                // ignore: unused_result
                                ref.refresh(backgroundServiceStatusStreamProvider);
                                // ignore: unused_result
                                ref.refresh(scheduledNotificationsProvider);
                                ref.read(channelListProvider.notifier).reloadState();
                              } else {
                                logger.debug("Widget unmounted, skipping 6s delayed refresh.");
                              }
                            });
                            },
                  ),
                ),
              ],
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
        ),
      ],
    );
  }
}
