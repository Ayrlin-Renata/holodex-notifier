import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

class RotatingFileWriter {
  final String baseFilename;
  final int maxFileSizeInBytes;
  final int maxFilesToKeep;
  final Lock _lock = Lock(); // Prevent race conditions during rotation

  String? _logDirectoryPath;
  File? _currentLogFile;
  IOSink? _currentSink;
  int _currentFileSize = 0;

  RotatingFileWriter({
    this.baseFilename = 'app_log',
    this.maxFileSizeInBytes = 5 * 1024 * 1024, // 5 MB default
    this.maxFilesToKeep = 3, // Keep current + 2 old files
  });

  Future<String> _getLogDirectory() async {
    if (_logDirectoryPath == null) {
      // Use cache directory as it's less critical than documents
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
  
  String get _currentLogPath => _currentLogFile?.path ?? 'unknown'; // Getter for current log path

  Future<void> write(String text) async {
    await _lock.synchronized(() async {
      final sink = await _getSink();
      final bytes = text.codeUnits;

      // Check if rotation is needed before writing
      if (_currentFileSize + bytes.length > maxFileSizeInBytes) {
        await _rotateLogs();
        // Need to re-get sink after rotation
        final newSink = await _getSink(); 
        newSink.writeln(text);
        _currentFileSize += bytes.length + 1; // +1 for newline
      } else {
        sink.writeln(text);
        _currentFileSize += bytes.length + 1; // +1 for newline
      }
      await sink.flush(); // Ensure it's written
    });
  }

  Future<void> _rotateLogs() async {
    print("[RotatingFileWriter] Rotating logs...");
    await _currentSink?.close();
    _currentSink = null;
    _currentLogFile = null; // Force re-evaluation of current log file path
    _currentFileSize = 0;

    final dir = await _getLogDirectory();
    final List<FileSystemEntity> files = Directory(dir).listSync()
      ..sort((a, b) {
        // Sort by last modified time, newest first
        return b.statSync().modified.compareTo(a.statSync().modified);
      });
    
    // Rename current log file (which is now the newest 'old' one)
    final File currentFileBeforeRotation = File(p.join(dir, '$baseFilename.log'));
    if(await currentFileBeforeRotation.exists()) {
       final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
       await currentFileBeforeRotation.rename(p.join(dir, '$baseFilename-$timestamp.log'));
       print("[RotatingFileWriter] Renamed previous log file.");
    }


    // Delete oldest files if exceeding limit
    if (files.length >= maxFilesToKeep) {
      final filesToDelete = files.skip(maxFilesToKeep -1); // Keep N-1 oldest + the newly renamed one
      for (final file in filesToDelete) {
        if (file is File) {
          try {
            await file.delete();
            print("[RotatingFileWriter] Deleted old log file: ${file.path}");
          } catch (e) {
             print("[RotatingFileWriter] Error deleting old log file ${file.path}: $e");
          }
        }
      }
    }
    
    // We will create a new sink/file on the next call to _getSink/_getLogFile
  }

  Future<void> close() async {
    await _lock.synchronized(() async {
       await _currentSink?.close();
        _currentSink = null;
       print("[RotatingFileWriter] Sink closed.");
    });
  }
  
  Future<String> getCurrentLogFilePath() async {
      final file = await _getLogFile();
      return file.path;
  }
   Future<String?> getMostRecentLogFileContent() async {
    return _lock.synchronized(() async {
      final file = await _getLogFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    });
  }
}