import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

class RotatingFileWriter {
  final String baseFilename;
  final int maxFileSizeInBytes;
  final int maxFilesToKeep;
  final Lock _lock = Lock();

  String? _logDirectoryPath;
  File? _currentLogFile;
  IOSink? _currentSink;
  int _currentFileSize = 0;

  Future<String> get currentLogFilePath async {
    final file = await _getLogFile();
    return file.path;
  }

  RotatingFileWriter({this.baseFilename = 'app_log', this.maxFileSizeInBytes = 5 * 1024 * 1024, this.maxFilesToKeep = 3});

  Future<String> _getLogDirectory() async {
    if (_logDirectoryPath == null) {
      final directory = await getTemporaryDirectory();
      _logDirectoryPath = p.join(directory.path, 'logs');
      await Directory(_logDirectoryPath!).create(recursive: true);
    }
    return _logDirectoryPath!;
  }

  Future<File> _getLogFile() async {
    if (_currentLogFile == null) {
      final dir = await _getLogDirectory();
      _currentLogFile = File(p.join(dir, '$baseFilename.log'));
      _currentFileSize = _currentLogFile!.existsSync() ? await _currentLogFile!.length() : 0;
    }
    return _currentLogFile!;
  }

  Future<IOSink> _getSink() async {
    if (_currentSink == null) {
      final file = await _getLogFile();
      _currentSink = file.openWrite(mode: FileMode.append);
    }
    return _currentSink!;
  }

  Future<void> write(String text) async {
    await _lock.synchronized(() async {
      final sink = await _getSink();
      final bytes = text.codeUnits;

      if (_currentFileSize + bytes.length > maxFileSizeInBytes) {
        await _rotateLogs();
        final newSink = await _getSink();
        newSink.writeln(text);
        _currentFileSize += bytes.length + 1;
      } else {
        sink.writeln(text);
        _currentFileSize += bytes.length + 1;
      }
      await sink.flush();
    });
  }

  Future<void> _rotateLogs() async {
    if (kDebugMode) {
      print("[RotatingFileWriter] Rotating logs...");
    }
    await _currentSink?.close();
    _currentSink = null;
    _currentLogFile = null;
    _currentFileSize = 0;

    final dir = await _getLogDirectory();
    final List<FileSystemEntity> files =
        Directory(dir).listSync()..sort((a, b) {
          return b.statSync().modified.compareTo(a.statSync().modified);
        });

    final File currentFileBeforeRotation = File(p.join(dir, '$baseFilename.log'));
    if (await currentFileBeforeRotation.exists()) {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      await currentFileBeforeRotation.rename(p.join(dir, '$baseFilename-$timestamp.log'));
      if (kDebugMode) {
        print("[RotatingFileWriter] Renamed previous log file.");
      }
    }

    if (files.length >= maxFilesToKeep) {
      final filesToDelete = files.skip(maxFilesToKeep - 1);
      for (final file in filesToDelete) {
        if (file is File) {
          try {
            await file.delete();
            if (kDebugMode) {
              print("[RotatingFileWriter] Deleted old log file: ${file.path}");
            }
          } catch (e) {
            if (kDebugMode) {
              print("[RotatingFileWriter] Error deleting old log file ${file.path}: $e");
            }
          }
        }
      }
    }
  }

  Future<void> close() async {
    await _lock.synchronized(() async {
      await _currentSink?.close();
      _currentSink = null;
      if (kDebugMode) {
        print("[RotatingFileWriter] Sink closed.");
      }
    });
  }

  Future<String?> getMostRecentLogFileContent({int? maxBytes}) async {
    final file = await _getLogFile();
    if (kDebugMode) {
      print("[RotatingFileWriter] Reading content from: ${file.path}${maxBytes != null ? ' (max: $maxBytes bytes)' : ''}");
    }

    if (await file.exists()) {
      try {
        final fileLength = await file.length();

        if (fileLength == 0) {
          if (kDebugMode) {
            print("[RotatingFileWriter] Log file is empty.");
          }
          return "";
        }

        if (maxBytes != null && fileLength > maxBytes) {
          if (kDebugMode) {
            print("[RotatingFileWriter] Log file size ($fileLength) exceeds maxBytes ($maxBytes). Reading tail.");
          }
          final stream = file.openRead(fileLength - maxBytes, fileLength);
          return await utf8.decodeStream(stream.cast<List<int>>());
        } else {
          if (kDebugMode) {
            print("[RotatingFileWriter] Reading full file ($fileLength bytes).");
          }
          return await file.readAsString();
        }
      } catch (e) {
        if (kDebugMode) {
          print("[RotatingFileWriter] Error reading ${maxBytes != null ? 'tail of' : ''} log file content: $e");
        }
        return null;
      }
    } else {
      if (kDebugMode) {
        print("[RotatingFileWriter] Log file does not exist: ${file.path}");
      }
      return null;
    }
  }
}