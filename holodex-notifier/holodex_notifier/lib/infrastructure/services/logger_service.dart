import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import riverpod
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/outputs/memory_log_output.dart';
import 'package:holodex_notifier/infrastructure/outputs/rotating_file_output.dart';
import 'package:holodex_notifier/infrastructure/outputs/rotating_file_writer.dart';
import 'package:holodex_notifier/main.dart';
import 'package:logger/logger.dart';

abstract class ILoggingServiceWithOutput extends ILoggingService {
  Stream<List<OutputEvent>> get logStream;
  Future<String> getLogFilePath();
  Future<String?> getLogFileContent(); // Method to read file
  MemoryLogOutput get memoryOutput; // Expose memory output directly
  void setSystemInfoString(String info); // {{ Add the method signature here }}
}

class LoggerService implements ILoggingServiceWithOutput {
  final MemoryLogOutput _memoryOutput = MemoryLogOutput(bufferSize: 200);
  final RotatingFileWriter _rotatingFileWriter = RotatingFileWriter(baseFilename: 'holodex_notifier');
  static const int _targetShareBytesLimit = 950 * 1024; // Target ~950 KB total
  static const int _logChunkMaxBytes = 300 * 1024; // Read max 300KB of logs initially
  late final RotatingFileOutput _rotatingFileOutput;
  late final Logger _logger;
  late final _logPrinter = SimplePrinter(
    colors: true, // {{ Disable colors for file/memory output printer }}
    printTime: true,
  );
  String _systemInfoString = 'System Info Not Initialized.'; // {{ Add field to store system info }}

  LoggerService() {
    // {{ Initialize custom output with the writer AND the printer }}
    _rotatingFileOutput = RotatingFileOutput(writer: _rotatingFileWriter);

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

  @override
  void setSystemInfoString(String info) {
    // {{ Implement the method }}
    _systemInfoString = info;
    _logger.i("LoggerService: System Info String updated.");
  }

  @override
  Stream<List<OutputEvent>> get logStream => _memoryOutput.stream;
  @override
  MemoryLogOutput get memoryOutput => _memoryOutput;

  @override
  Future<String> getLogFilePath() async {
    return _rotatingFileWriter.currentLogFilePath;
  }

  @override
  Future<String?> getLogFileContent() async {
    // {{ Log using the smaller, fixed chunk size }}
    _logger.d("Getting log file content for sharing (Reading max: $_logChunkMaxBytes bytes)...");
    await _rotatingFileWriter.close(); // Ensure flush

    // {{ Request the reduced, fixed size chunk for the log file }}
    final logContent = await _rotatingFileWriter.getMostRecentLogFileContent(maxBytes: _logChunkMaxBytes);

    if (logContent == null) {
      _logger.w("Failed to read log file content.");
      return "$_systemInfoString\n\n(No log file content found or error reading file)";
    }

    final int logContentChars = logContent.length;
    _logger.d("Log content raw read successful (Chars: $logContentChars). Prepending system info.");

    // Prepend the stored system info string and header
    String contentToShare = "$_systemInfoString\n\n--- Log Start (Last ~${_logChunkMaxBytes ~/ 1024} KB of file) ---\n$logContent";

    // --- Final Size Check ---
    final int finalByteLength;
    try {
      finalByteLength = utf8.encode(contentToShare).length; // Check actual byte length after combining
      _logger.d("Constructed contentToShare. Final Encoded Byte Length: $finalByteLength");
    } catch (e) {
      _logger.e("Error encoding final contentToShare: $e. Cannot verify size.");
      // Proceed with potentially oversized content if encoding fails? Or return error?
      // Let's proceed for now, but log error.
      return contentToShare; // Return potentially oversized content
    }

    // Check if exceeds the target limit
    if (finalByteLength > _targetShareBytesLimit) {
      _logger.w("Final content size ($finalByteLength bytes) exceeds target limit ($_targetShareBytesLimit bytes). Truncating string...");
      // Truncate the STRING to fit the byte limit. This isn't perfect for multi-byte chars at the boundary, but safer than crashing.
      // We need to know how many CHARACTERS correspond roughly to the byte limit.
      // Estimate characters based on average bytes per char, but with a safety margin.
      double avgBytesPerChar = finalByteLength / contentToShare.length;
      if (avgBytesPerChar <= 0) avgBytesPerChar = 1.0; // Avoid division by zero / negative

      // Calculate target character count, give some buffer (e.g., 98% of target bytes)
      int targetCharCount = ((_targetShareBytesLimit * 0.98) / avgBytesPerChar).floor();

      // Ensure we don't truncate *before* the system info + header
      final headerLengthEstimate = ("$_systemInfoString\n\n--- Log Start (...) ---\n").length;
      targetCharCount = max(headerLengthEstimate + 100, targetCharCount); // Ensure header + some log remains

      if (targetCharCount < contentToShare.length) {
        contentToShare = "${contentToShare.substring(0, targetCharCount)}\n\n--- TRUNCATED due to size limit ---";
        _logger.d("Truncated contentToShare to $targetCharCount characters.");
      } else {
        _logger.w(
          "Calculated target character count ($targetCharCount) is not smaller than original length (${contentToShare.length}). Truncation ineffective?",
        );
        // This might happen if the string is enormous and system info/headers dominate.
        // Let's still attempt a more aggressive truncation based only on the byte limit
        // This is risky and might cut off the header, but better than crashing.
        const fallbackMaxChars = (_targetShareBytesLimit ~/ 1.5); // Very rough estimate based on 1.5 byte/char avg
        if (contentToShare.length > fallbackMaxChars) {
          contentToShare = "${contentToShare.substring(0, fallbackMaxChars)}\n\n--- Aggressively TRUNCATED ---";
          _logger.d("Aggressively truncated contentToShare to $fallbackMaxChars characters.");
        }
      }
    }
    // --- End Final Size Check ---

    return contentToShare;
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
