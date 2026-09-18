/// Frames concatenated JSON objects independently of TCP packet boundaries.
/// A new instance is used for every connection, including UTF-8 decoding.
class RobotJsonBuffer {
  RobotJsonBuffer({this.maxMessageLength = 1024 * 1024});

  final int maxMessageLength;
  StringBuffer _buffer = StringBuffer();
  int _depth = 0;
  bool _inString = false;
  bool _escaping = false;

  Iterable<String> add(String chunk) sync* {
    for (final code in chunk.codeUnits) {
      if (_depth == 0) {
        if (code != 123)
          continue; // Existing protocol allows surrounding whitespace.
        _depth = 1;
        _buffer.writeCharCode(code);
        continue;
      }
      _buffer.writeCharCode(code);
      if (_buffer.length > maxMessageLength) {
        throw const FormatException(
            'Messaggio robot oltre il limite di memoria');
      }
      if (_escaping) {
        _escaping = false;
      } else if (_inString && code == 92) {
        _escaping = true;
      } else if (code == 34) {
        _inString = !_inString;
      } else if (!_inString) {
        if (code == 123) _depth++;
        if (code == 125) _depth--;
        if (_depth == 0) {
          final message = _buffer.toString();
          _buffer = StringBuffer();
          yield message;
        }
      }
    }
  }
}
