import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/infrastructure/services/logger_service.dart';
import 'package:holodex_notifier/main.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

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
                loggerService.info('AppController: Creating and sharing log ZIP archive...');
                try {
                  final logFilePaths = await loggerService.getLogFilePaths();
                  if (logFilePaths.isEmpty) {
                    loggerService.warning('AppController: No log files paths provided for ZIP.');
                    return;
                  }

                  final archive = Archive();
                  for (final logFilePath in logFilePaths) {
                    final file = File(logFilePath);
                    if (await file.exists()) {
                      final filename = p.basename(logFilePath);
                      final fileBytes = await file.readAsBytes();
                      archive.addFile(ArchiveFile(filename, fileBytes.length, fileBytes));
                      loggerService.debug('AppController: Added file "$filename" to ZIP archive.');
                    } else {
                      loggerService.warning('AppController: Log file not found at path: $logFilePath');
                    }
                  }

                  if (archive.isEmpty) {
                    loggerService.warning('AppController: No files added to ZIP archive. Aborting share.');
                    return;
                  }

                  final tempDir = await getTemporaryDirectory();
                  final zipFilePath = p.join(tempDir.path, 'holodex_notifier_logs.zip');
                  final zipFile = File(zipFilePath);

                  ZipFileEncoder encoder = ZipFileEncoder();
                  encoder.create(zipFilePath); // Create the zip file
                  encoder.addFile(zipFile); // Add the archive into the zip file
                  encoder.close();

                  loggerService.debug('AppController: ZIP archive created at: $zipFilePath');

                  final result = await Share.shareXFiles([XFile(zipFilePath)], text: 'Holodex Notifier Logs', subject: 'HolodexNotifier_Logs');

                  if (result.status == ShareResultStatus.success) {
                    loggerService.info('AppController: Log ZIP archive shared successfully.');
                    return;
                  } else {
                    loggerService.warning('AppController: Log ZIP sharing status: ${result.status}');
                    return;
                  }
                } catch (e, s) {
                  loggerService.error('AppController: Failed to create and share log ZIP archive.', e, s);
                  return;
                } 
              } else {
                loggerService.error("Attempted to share logs, but logger service is not ILoggingServiceWithOutput");
                if (context.mounted) {
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
