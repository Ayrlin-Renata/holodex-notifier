import 'package:flutter/material.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/main.dart';
import 'package:intl/intl.dart';

class BackgroundStatusCard extends HookConsumerWidget {
  const BackgroundStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(backgroundServiceStatusStreamProvider);
    final pollFrequency = ref.watch(pollFrequencyProvider);

    final logger = ref.watch(loggingServiceProvider);

    return statusAsync.when(
      data: (status) {
        final nextPollTime = status.lastPollTime?.add(pollFrequency);
        final lastError = status.lastError;
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),

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
                            ref.invalidate(backgroundServiceStatusStreamProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Poll Now'),
                      onPressed:
                          !status.isRunning
                              ? null
                              : () {
                                logger.info("[UI] Invoking manual poll...");
                                ref.read(backgroundServiceProvider).triggerPoll();
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Manual poll triggered...'), duration: Duration(seconds: 2)),
                                );
                                ref.invalidate(backgroundServiceStatusStreamProvider);
                              },
                    ),

                    TextButton.icon(
                      icon: Icon(status.isRunning ? Icons.restart_alt : Icons.play_arrow_outlined, size: 18),
                      label: Text(status.isRunning ? 'Restart Service' : 'Start Service'),
                      onPressed: () async {
                        final service = ref.read(backgroundServiceProvider);
                        if (status.isRunning) {
                          logger.info("[UI] Attempting Background Service RESTART...");
                          service.stopPolling();
                          await Future.delayed(const Duration(milliseconds: 500));
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
                        await Future.delayed(const Duration(milliseconds: 1000));
                        ref.invalidate(backgroundServiceStatusStreamProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () => Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator())),
          ),
      error:
          (error, stack) => Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.7)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text('Error loading status: $error', style: TextStyle(color: theme.colorScheme.error))),
            ),
          ),
    );
  }
}
