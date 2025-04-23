import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/outputs/memory_log_output.dart';
import 'package:holodex_notifier/infrastructure/outputs/rotating_file_output.dart';
import 'package:holodex_notifier/infrastructure/outputs/rotating_file_writer.dart';
import 'package:holodex_notifier/main.dart';
import 'package:logger/logger.dart';

abstract class ILoggingServiceWithOutput extends ILoggingService {
  Stream<List<OutputEvent>> get logStream;
  Future<String> getLogFilePath();
  Future<String?> getLogFileContent();
  MemoryLogOutput get memoryOutput;
  void setSystemInfoString(String info);
  Future<List<String>> getLogFilePaths();
}

class LoggerService implements ILoggingServiceWithOutput {
  final MemoryLogOutput _memoryOutput = MemoryLogOutput(bufferSize: 200);
  final RotatingFileWriter _rotatingFileWriter = RotatingFileWriter(baseFilename: 'holodex_notifier');
  static const int _targetShareBytesLimit = 950 * 1024;
  static const int _logChunkMaxBytes = 300 * 1024;
  late final RotatingFileOutput _rotatingFileOutput;
  late final Logger _logger;
  late final _logPrinter = SimplePrinter(colors: true, printTime: true);
  String _systemInfoString = 'System Info Not Initialized.';

  LoggerService() {
    _rotatingFileOutput = RotatingFileOutput(writer: _rotatingFileWriter);

    _logger = Logger(
      printer: _logPrinter,
      output: MultiOutput([ConsoleOutput(), _rotatingFileOutput, _memoryOutput]),
      level: Level.trace,
      filter: ProductionFilter(),
    );
    _logger.i("LoggerService initialized with Console, RotatingFile, and Memory outputs.");
  }

  @override
  void setSystemInfoString(String info) {
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
    _logger.d("Getting log file content for sharing (Reading max: $_logChunkMaxBytes bytes)...");
    await _rotatingFileWriter.close();

    final logContent = await _rotatingFileWriter.getMostRecentLogFileContent(maxBytes: _logChunkMaxBytes);

    if (logContent == null) {
      _logger.w("Failed to read log file content.");
      return "$_systemInfoString\n\n(No log file content found or error reading file)";
    }

    final int logContentChars = logContent.length;
    _logger.d("Log content raw read successful (Chars: $logContentChars). Prepending system info.");

    String contentToShare = "$_systemInfoString\n\n--- Log Start (Last ~${_logChunkMaxBytes ~/ 1024} KB of file) ---\n$logContent";

    final int finalByteLength;
    try {
      finalByteLength = utf8.encode(contentToShare).length;
      _logger.d("Constructed contentToShare. Final Encoded Byte Length: $finalByteLength");
    } catch (e) {
      _logger.e("Error encoding final contentToShare: $e. Cannot verify size.");
      return contentToShare;
    }

    if (finalByteLength > _targetShareBytesLimit) {
      _logger.w("Final content size ($finalByteLength bytes) exceeds target limit ($_targetShareBytesLimit bytes). Truncating string...");
      double avgBytesPerChar = finalByteLength / contentToShare.length;
      if (avgBytesPerChar <= 0) avgBytesPerChar = 1.0;

      int targetCharCount = ((_targetShareBytesLimit * 0.98) / avgBytesPerChar).floor();

      final headerLengthEstimate = ("$_systemInfoString\n\n--- Log Start (...) ---\n").length;
      targetCharCount = max(headerLengthEstimate + 100, targetCharCount);

      if (targetCharCount < contentToShare.length) {
        contentToShare = "${contentToShare.substring(0, targetCharCount)}\n\n--- TRUNCATED due to size limit ---";
        _logger.d("Truncated contentToShare to $targetCharCount characters.");
      } else {
        _logger.w(
          "Calculated target character count ($targetCharCount) is not smaller than original length (${contentToShare.length}). Truncation ineffective?",
        );
        const fallbackMaxChars = (_targetShareBytesLimit ~/ 1.5);
        if (contentToShare.length > fallbackMaxChars) {
          contentToShare = "${contentToShare.substring(0, fallbackMaxChars)}\n\n--- Aggressively TRUNCATED ---";
          _logger.d("Aggressively truncated contentToShare to $fallbackMaxChars characters.");
        }
      }
    }

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

  @override
  Future<List<String>> getLogFilePaths() async {
    _logger.i('LoggerService: Getting all log file paths.');
    try {
      final logFilePaths = await _rotatingFileWriter.getAllLogFilePaths();

      const alarmFilePath = '/storage/emulated/0/Documents/HolodexNotifier/logs/background_alarm_error_log.txt';
      logFilePaths.add(alarmFilePath);

      if (logFilePaths.isEmpty) {
        _logger.w('LoggerService: No log file paths found.');
        return [];
      }

      return logFilePaths;
    } catch (e, s) {
      _logger.e('LoggerService: Error during log file path finding process.', error: e, stackTrace: s);
      return [];
    }
  }
}

final recentLogsProvider = StreamProvider<List<OutputEvent>>((ref) {
  final loggerService = ref.watch(loggingServiceProvider);
  if (loggerService is ILoggingServiceWithOutput) {
    return loggerService.logStream;
  } else {
    return Stream.value([]);
  }
}, name: 'recentLogsProvider');

String formatLogEvent(OutputEvent event) {
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
