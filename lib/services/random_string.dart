import 'dart:math';

class RandomString {
  static final _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
  static final Random _rnd = Random();

  static String generate(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}
