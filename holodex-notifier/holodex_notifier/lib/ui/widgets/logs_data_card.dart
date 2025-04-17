import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/infrastructure/services/logger_service.dart';
import 'package:holodex_notifier/main.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';

class LogsDataCard extends ConsumerWidget {
  const LogsDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(recentLogsProvider);
    final loggerService = ref.watch(loggingServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final appController = ref.watch(appControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
          child: Text('Application Logs & Configuration', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
        ),
        const SizedBox(height: 8.0),

        Text('Recent Log Output:', style: theme.textTheme.labelMedium),
        const SizedBox(height: 4.0),
        Container(
          height: 300,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: logsAsync.when(
            data:
                (logEvents) => SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: logEvents.map((event) => _buildLogEntryWidget(event, theme)).toList(),
                  ),
                ),
            loading: () => const Center(child: Text("Initializing log stream...")),
            error: (err, stack) => Center(child: Text("Error loading logs: $err")),
          ),
        ),
        const SizedBox(height: 16.0),

        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Share Full Log'),
            onPressed: () async {
              if (loggerService is ILoggingServiceWithOutput) {
                try {
                  final logContent = await loggerService.getLogFileContent();
                  if (logContent == null) {
                    throw Exception("Failed to retrieve log content.");
                  }

                  final result = await Share.share(logContent, subject: 'Holodex Notifier Logs');

                  if (result.status == ShareResultStatus.success) {
                    print('Log content shared successfully.');
                  } else if (result.status == ShareResultStatus.dismissed) {
                    print('Log sharing dismissed by user.');
                  } else {
                    print('Log sharing failed: ${result.status}');
                    if (context.mounted) {
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to share log: ${result.status}')));
                    }
                  }
                } catch (e) {
                  print('Error sharing log content: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error preparing log for sharing: $e')));
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log service error: Cannot share logs.')));
              }
            },
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ),
        const SizedBox(height: 16.0),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Export Config'),
              onPressed: () async {
                final success = await appController.exportConfiguration();
                if (context.mounted) {
                  if (!success) {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to export configuration.')));
                  }
                }
              },
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            TextButton.icon(
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Import Config'),
              onPressed: () async {
                final success = await appController.importConfiguration();
                if (context.mounted) {
                  if (success) {
                    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Configuration imported successfully! UI refreshing...')));
                  } else {
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

  Widget _buildLogEntryWidget(OutputEvent event, ThemeData theme) {
    final color = getLogColor(event, theme);
    final text = formatLogEvent(event);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color, fontFamily: 'monospace', fontSize: 10)),
    );
  }
}
