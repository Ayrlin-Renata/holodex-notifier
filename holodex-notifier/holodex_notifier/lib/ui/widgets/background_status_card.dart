// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\ui\widgets\background_status_card.dart
import 'package:flutter/material.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart'; // For pollFrequencyProvider
import 'package:holodex_notifier/main.dart'; // For backgroundServiceProvider, loggingServiceProvider
import 'package:intl/intl.dart'; // For date formatting
// {{ Add import for IBackgroundPollingService }}

// ... existing code ...

class BackgroundStatusCard extends HookConsumerWidget {
  const BackgroundStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(backgroundServiceStatusStreamProvider);
    final pollFrequency = ref.watch(pollFrequencyProvider);

    final logger = ref.watch(loggingServiceProvider); // Get logger

    return statusAsync.when(
      data: (status) {
        final nextPollTime = status.lastPollTime?.add(pollFrequency);
        final lastError = status.lastError;
        // {{ Remove unused AppController }}
        // final appController = ref.watch(appControllerProvider);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                if (lastError != null) // {{ Cleaned up error display logic slightly }}
                  Container( // ... Error Container ...
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: Row( // ... Error Row ...
                      children: [ // ... Error children ...
                        Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last Error: $lastError',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                        IconButton( // ... Clear button ...
                          icon: Icon(Icons.clear, size: 16, color: theme.colorScheme.onErrorContainer),
                          tooltip: 'Clear Error Message',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            ref.read(backgroundLastErrorProvider.notifier).state = null;
                            // {{ Refresh provider directly }}
                            ref.invalidate(backgroundServiceStatusStreamProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space buttons
                  children: [
                    // Poll Now Button (Keep as TextButton)
                    TextButton.icon(
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Poll Now'),
                      onPressed: !status.isRunning
                          ? null
                          : () {
                              logger.info("[UI] Invoking manual poll...");
                              // {{ Use backgroundServiceProvider to invoke }}
                              ref.read(backgroundServiceProvider).triggerPoll();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text('Manual poll triggered...'), duration: Duration(seconds: 2)),
                              );
                              // {{ Refresh provider directly }}
                              ref.invalidate(backgroundServiceStatusStreamProvider);
                              // {{ Simplified refresh logic - rely on status stream updates }}
                              // Future.delayed(...) // Consider removing this delay/refresh block if status stream updates are reliable
                            },
                    ),

                    TextButton.icon( // Use ElevatedButton for primary action
                      icon: Icon(status.isRunning ? Icons.restart_alt : Icons.play_arrow_outlined, size: 18),
                      label: Text(status.isRunning ? 'Restart Service' : 'Start Service'),
                      onPressed: () async {
                        final service = ref.read(backgroundServiceProvider);
                        if (status.isRunning) {
                          logger.info("[UI] Attempting Background Service RESTART...");
                          // No need for 'await' here if we trigger refresh immediately
                          service.stopPolling();
                          await Future.delayed(const Duration(milliseconds: 500)); // Short delay to ensure stop command is processed
                          service.startPolling();
                           scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Restarting background service...'), duration: Duration(seconds: 2)),
                          );
                        } else {
                           logger.info("[UI] Attempting Background Service START...");
                           service.startPolling();
                            scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Starting background service...'), duration: Duration(seconds: 2)),
                           );
                        }
                        // Refresh status after a short delay to allow service state to update
                        await Future.delayed(const Duration(milliseconds: 1000));
                         ref.invalidate(backgroundServiceStatusStreamProvider);
                      },
                    ),
                    // ****** END CHANGE ******
                  ],
                ),
              ],
            ),
          ),
        );
      },
      // ... loading & error states ...
       loading: () => Card( // {{ Show card structure while loading }}
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 1,
         shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card( // {{ Show card structure on error }}
         margin: const EdgeInsets.symmetric(vertical: 8.0),
         elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.7)),
          ),
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Center(
              child: Text('Error loading status: $error', style: TextStyle(color: theme.colorScheme.error)),
           ),
         ),
      ),
    );
  }
}