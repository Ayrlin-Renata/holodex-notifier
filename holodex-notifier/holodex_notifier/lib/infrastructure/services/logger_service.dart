import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:logger/logger.dart'; // Import logger package

class LoggerService implements ILoggingService {
  // Hold Logger instance, configure it
  final Logger _logger = Logger(
     printer: SimplePrinter(
        colors: true, // Keep colors
        printTime: true, // Print timestamp
     ),
     // Optional: Add output listeners, e.g., file output
     // output: MultiOutput([
     //   ConsoleOutput(),
     //   // FileOutput(file: File('app.log')), // Need to add file_support dependency
     // ]),
     // Set minimum level for logs to be processed
     level: Level.debug, // Log everything in debug, maybe Level.info in release
     filter: ProductionFilter(), // Keep the filter if needed, SimplePrinter doesn't show stack trace by default
  );

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
     // Logger calls 'wtf' (What a Terrible Failure) for fatal level
     _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
