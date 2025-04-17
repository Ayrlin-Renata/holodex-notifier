import 'dart:async';
import 'dart:collection';
import 'package:logger/logger.dart';

class MemoryLogOutput extends LogOutput {
  final Level minLevelForUi;
  final int bufferSize;
  final Queue<OutputEvent> _buffer;
  final StreamController<List<OutputEvent>> _controller = StreamController.broadcast();

  MemoryLogOutput({this.bufferSize = 100, this.minLevelForUi = Level.info}) : _buffer = Queue<OutputEvent>();

  Stream<List<OutputEvent>> get stream => _controller.stream;
  List<OutputEvent> get currentLogs => List.unmodifiable(_buffer);

  @override
  void output(OutputEvent event) {
    if (event.level.index >= minLevelForUi.index) {
      if (_buffer.length >= bufferSize) {
        _buffer.removeFirst();
      }
      _buffer.add(event);
      _controller.add(List.unmodifiable(_buffer));
    }
  }

  @override
  Future<void> destroy() async {
    _buffer.clear();
    await _controller.close();
    super.destroy();
  }
}
