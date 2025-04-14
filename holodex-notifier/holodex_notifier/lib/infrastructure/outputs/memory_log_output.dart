import 'dart:async';
import 'dart:collection';
import 'package:logger/logger.dart';

class MemoryLogOutput extends LogOutput {
  final Level minLevelForUi; 
  final int bufferSize;
  final Queue<OutputEvent> _buffer;
  final StreamController<List<OutputEvent>> _controller = StreamController.broadcast();

  MemoryLogOutput({
    this.bufferSize = 100,
    this.minLevelForUi = Level.info, // Default to info level for UI
  }) : _buffer = Queue<OutputEvent>();

  Stream<List<OutputEvent>> get stream => _controller.stream;
  List<OutputEvent> get currentLogs => List.unmodifiable(_buffer);

  @override
  void output(OutputEvent event) {
    // {{ Filter Based on Level before adding to UI buffer/stream }}
    if (event.level.index >= minLevelForUi.index) { 
      if (_buffer.length >= bufferSize) {
        _buffer.removeFirst();
      }
      _buffer.add(event);
      // Emit a new list copy to the stream
      _controller.add(List.unmodifiable(_buffer));
    }
    // Events below minLevelForUi are simply skipped for this output
  }

  @override
  Future<void> destroy() async {
     _buffer.clear();
    await _controller.close();
    super.destroy();
  }
}