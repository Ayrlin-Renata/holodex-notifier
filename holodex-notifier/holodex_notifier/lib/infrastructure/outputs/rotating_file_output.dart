import 'package:holodex_notifier/infrastructure/outputs/rotating_file_writer.dart';
import 'package:logger/logger.dart';

/// A custom LogOutput that writes formatted log messages to a RotatingFileWriter.
class RotatingFileOutput extends LogOutput {
  final RotatingFileWriter _writer;


  RotatingFileOutput({
    required RotatingFileWriter writer,
  }) : _writer = writer;

  @override
  void output(OutputEvent event) {
    // The event already contains formatted lines from the Logger's printer.
    // Join the lines and write to the rotating file writer.
    final String formattedLog = event.lines.join('\n');
    _writer.write(formattedLog);
  }

  @override
  Future<void> destroy() async {
    await _writer.close(); // Ensure the writer is closed properly
    super.destroy();
  }
}
