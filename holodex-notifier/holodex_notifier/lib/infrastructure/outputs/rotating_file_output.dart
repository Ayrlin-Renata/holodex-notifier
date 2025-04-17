import 'package:holodex_notifier/infrastructure/outputs/rotating_file_writer.dart';
import 'package:logger/logger.dart';

class RotatingFileOutput extends LogOutput {
  final RotatingFileWriter _writer;

  RotatingFileOutput({required RotatingFileWriter writer}) : _writer = writer;

  @override
  void output(OutputEvent event) {
    final String formattedLog = event.lines.join('\n');
    _writer.write(formattedLog);
  }

  @override
  Future<void> destroy() async {
    await _writer.close();
    super.destroy();
  }
}
