import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/infrastructure/services/logger_service.dart'; // Import new providers/helpers
import 'package:holodex_notifier/main.dart';
import 'package:logger/logger.dart'; // Import OutputEvent
import 'package:share_plus/share_plus.dart'; // Import share_plus

class LogsDataCard extends ConsumerWidget {
  const LogsDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(recentLogsProvider); // Watch the new stream provider
    final loggerService = ref.watch(loggingServiceProvider); // Get the service instance
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Get messenger
    final appController = ref.watch(appControllerProvider); // {{ Get AppController }}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Section Title ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
          child: Text('Application Logs & Configuration', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
        ),
        const SizedBox(height: 8.0),

        // --- Live Log View ---
        Text('Recent Log Output:', style: theme.textTheme.labelMedium),
        const SizedBox(height: 4.0),
        Container(
          height: 300, // Fixed height for the log view
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest, // Use a slightly different background
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: logsAsync.when(
            data:
                (logEvents) => SingleChildScrollView(
                  reverse: true, // Show latest logs at the bottom and auto-scroll
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Map OutputEvent to styled Text widgets
                    children: logEvents.map((event) => _buildLogEntryWidget(event, theme)).toList(),
                  ),
                ),
            loading: () => const Center(child: Text("Initializing log stream...")),
            error: (err, stack) => Center(child: Text("Error loading logs: $err")),
          ),
        ),
        const SizedBox(height: 16.0),

        // --- Share Log Button ---
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Share Full Log'),
            onPressed: () async {
              // {{ Implement sharing }}
              if (loggerService is ILoggingServiceWithOutput) {
                try {
                  final filePath = await loggerService.getLogFilePath();
                  final result = await Share.shareXFiles([XFile(filePath)], text: 'Holodex Notifier Logs');

                  if (result.status == ShareResultStatus.success) {
                    print('Log file shared successfully.');
                    // Optional: Show success snackbar if desired
                    // scaffoldMessenger.showSnackBar(
                    //   const SnackBar(content: Text('Log shared successfully.')),
                    // );
                  } else if (result.status == ShareResultStatus.dismissed) {
                    print('Log file sharing dismissed by user.');
                    // Do NOT show a snackbar for dismissal
                  } else {
                    // Handle other failure statuses (unavailable, etc.)
                    print('Log file sharing failed: ${result.status}');
                    if (context.mounted) {
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to share log: ${result.status}')));
                    }
                  }
                } catch (e) {
                  print('Error sharing log file: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error preparing log for sharing: $e')));
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log service error: Cannot share file.')));
              }
            },
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ),
        const SizedBox(height: 16.0),

        // --- Import/Export Buttons ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Export Config'),
              // {{ Add async and connect to controller }}
              onPressed: () async {
                final success = await appController.exportConfiguration();
                if (context.mounted) {
                  if (!success) {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to export configuration.')));
                  }
                  // No snackbar on success, Share sheet provides feedback
                }
              },
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            TextButton.icon(
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Import Config'),
              // {{ Add async and connect to controller }}
              onPressed: () async {
                final success = await appController.importConfiguration();
                if (context.mounted) {
                  if (success) {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Configuration imported successfully! UI refreshing...')));
                  } else {
                    // Failure or cancellation message handled inside controller or shown by picker
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Configuration import failed or canceled.')));
                  }
                }
              },
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
      ],
    );
  }

  // Build widget for a single log event
  Widget _buildLogEntryWidget(OutputEvent event, ThemeData theme) {
    final color = getLogColor(event, theme); // Use helper from logger_service
    final text = formatLogEvent(event); // Use helper from logger_service

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0), // Reduced padding
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontFamily: 'monospace', // Use monospace for logs
          fontSize: 10, // Make logs slightly smaller
        ),
      ),
    );
  }

  // REMOVE: old _buildLogEntry method that took a string
}
