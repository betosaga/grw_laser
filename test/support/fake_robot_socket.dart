import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A controllable byte stream; no test connects to robot hardware.
class FakeRobotSocket extends Stream<Uint8List> implements Socket {
  final input = StreamController<Uint8List>();
  final outputDone = Completer<void>();
  final List<String> writes = [];
  bool destroyed = false;
  bool failWrite = false;

  void receive(String text) => input.add(Uint8List.fromList(utf8.encode(text)));
  void message(Map<String, dynamic> msg) => receive(jsonEncode({'MSG': msg}));

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      input.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  void write(Object? value) {
    if (failWrite) throw const SocketException('simulated write failure');
    writes.add(value.toString());
  }

  @override
  bool setOption(SocketOption option, bool enabled) => true;

  @override
  Future<void> get done => outputDone.future;

  @override
  void destroy() {
    destroyed = true;
    if (!outputDone.isCompleted) outputDone.complete();
    unawaited(input.close());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
