import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import riverpod
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/outputs/memory_log_output.dart';
import 'package:holodex_notifier/infrastructure/outputs/rotating_file_output.dart';
import 'package:holodex_notifier/infrastructure/outputs/rotating_file_writer.dart';
import 'package:holodex_notifier/main.dart';
import 'package:logger/logger.dart';

// Extend interface to include file path and stream
abstract class ILoggingServiceWithOutput extends ILoggingService {
  Stream<List<OutputEvent>> get logStream;
  Future<String> getLogFilePath();
  Future<String?> getLogFileContent(); // Method to read file
  MemoryLogOutput get memoryOutput; // Expose memory output directly
}

class LoggerService implements ILoggingServiceWithOutput {
  final MemoryLogOutput _memoryOutput = MemoryLogOutput(bufferSize: 200);
  final RotatingFileWriter _rotatingFileWriter = RotatingFileWriter(baseFilename: 'holodex_notifier');
  // {{ Use the custom RotatingFileOutput }}
  late final RotatingFileOutput _rotatingFileOutput;
  late final Logger _logger;
  late final _logPrinter = SimplePrinter(
    colors: true, // {{ Disable colors for file/memory output printer }}
    printTime: true,
  );

  LoggerService() {
    // {{ Initialize custom output with the writer AND the printer }}
    _rotatingFileOutput = RotatingFileOutput(
      writer: _rotatingFileWriter,
    );

    _logger = Logger(
      printer: _logPrinter,
      output: MultiOutput([
        ConsoleOutput(),
        _rotatingFileOutput, // Use custom file output
        _memoryOutput, // Use memory output (doesn't need explicit printer)
      ]),
      level: Level.trace,
      filter: ProductionFilter(), // Keep ProductionFilter
    );
    _logger.i("LoggerService initialized with Console, RotatingFile, and Memory outputs.");
  }

  // ... rest of the LoggerService methods remain the same ...
  @override
  Stream<List<OutputEvent>> get logStream => _memoryOutput.stream;
  @override
  MemoryLogOutput get memoryOutput => _memoryOutput;

  @override
  Future<String> getLogFilePath() async {
    return _rotatingFileWriter.getCurrentLogFilePath();
  }

  @override
  Future<String?> getLogFileContent() async {
    return await _rotatingFileWriter.getMostRecentLogFileContent();
  }

  @override
  void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

// New provider for the recent log stream
final recentLogsProvider = StreamProvider.autoDispose<List<OutputEvent>>((ref) {
  // Watch the main logging service provider to ensure it's initialized
  final loggerService = ref.watch(loggingServiceProvider);
  // Cast to the extended interface to access the stream
  if (loggerService is ILoggingServiceWithOutput) {
    // Return the stream from the service
    return loggerService.logStream;
  } else {
    // Handle error case where the service doesn't have the stream (shouldn't happen)
    return Stream.value([]);
  }
}, name: 'recentLogsProvider');

// --- Simple Log Formatting Helper for UI --- (Can place elsewhere if preferred)
String formatLogEvent(OutputEvent event) {
  // Basic text formatting, can be enhanced
  return event.lines.join('\n');
}

Color getLogColor(OutputEvent event, ThemeData theme) {
  Level level = event.level;
  if (level == Level.trace) return Colors.grey.shade700;
  if (level == Level.debug) return Colors.grey.shade500;
  if (level == Level.info) return Colors.blue.shade300;
  if (level == Level.warning) return Colors.orange.shade400;
  if (level == Level.error || level == Level.fatal) return Colors.red.shade400;
  return theme.textTheme.bodySmall?.color ?? Colors.white;
}
