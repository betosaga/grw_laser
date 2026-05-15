
extension IntToHexStringExtension on int {
  String toHexString() {
    return '0x' + this.toRadixString(16).padLeft(2, '0').toUpperCase();
  }
}
