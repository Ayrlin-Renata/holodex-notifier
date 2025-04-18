import 'dart:io'; // Add dart:io import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/infrastructure/services/logger_service.dart';
import 'package:holodex_notifier/main.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart'; // Add path_provider import
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
                String? tempLogFilePath; // To store path for cleanup
                try {
                  // Get log content
                  final logContent = await loggerService.getLogFileContent();
                  if (logContent == null || logContent.isEmpty) {
                    loggerService.warning('Log content is empty or unavailable for sharing.');
                    if (context.mounted) {
                      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Log content is empty or could not be retrieved.')));
                    }
                    return; // Exit if no content
                  }
                  loggerService.debug("Log content length for sharing: ${logContent.length} characters");

                  // Get temporary directory
                  final tempDir = await getTemporaryDirectory();
                  final fileName = 'holodex_notifier_logs_${DateTime.now().millisecondsSinceEpoch}.txt';
                  final logFile = File('${tempDir.path}/$fileName');
                  tempLogFilePath = logFile.path; // Store path for potential cleanup

                  // Write content to the file
                  await logFile.writeAsString(logContent);
                  loggerService.info("Log content written to temporary file: ${logFile.path}");

                  // Prepare file for sharing
                  final xFile = XFile(logFile.path, mimeType: 'text/plain'); // Specify MIME type
                  final shareSubject = 'Holodex Notifier Logs ${DateTime.now().toIso8601String().substring(0, 10)}';

                  // Share the file using shareXFiles
                  final result = await Share.shareXFiles([xFile], subject: shareSubject);

                  // Handle the result status
                  if (result.status == ShareResultStatus.success) {
                    loggerService.info('Log file shared successfully: ${logFile.path}');
                  } else if (result.status == ShareResultStatus.dismissed) {
                    loggerService.info('Log file sharing dismissed by user.');
                  } else {
                     // Log the specific raw status value if available for more info
                    loggerService.warning('Log file sharing failed: Status=${result.status}, RawValue=${result.raw}');
                    if (context.mounted) {
                       // Show more informative message, including the specific status
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to share log file. Status: ${result.status}')));
                    }
                  }
                } catch (e, s) {
                  loggerService.error('Error preparing or sharing log file', e, s);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error preparing log file for sharing: $e')));
                  }
                } finally {
                  // Optional: Attempt to clean up the temporary file
                  if (tempLogFilePath != null) {
                    try {
                      final fileToDelete = File(tempLogFilePath);
                      if (await fileToDelete.exists()) {
                        await fileToDelete.delete();
                        loggerService.debug("Temporary log file deleted: $tempLogFilePath");
                      }
                    } catch (e) {
                       loggerService.warning("Failed to delete temporary log file: $tempLogFilePath. Error: $e");
                    }
                  }
                }
              } else {
                // Handle case where logger service doesn't support file output
                loggerService.error("Attempted to share logs, but logger service is not ILoggingServiceWithOutput");
                if (context.mounted){
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log service error: Cannot retrieve logs for sharing.')));
                }
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