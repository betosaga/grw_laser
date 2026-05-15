import 'dart:typed_data';
import 'package:grw_laser/extensions/int_to_hex_string_extension.dart';

extension Uint8ListToHexStringExtension on Uint8List {
  String toHexString({String empty = '-', String separator = ' '}) {
    return isEmpty ? empty : this.map((e) => e.toHexString()).join(separator);
  }
}
