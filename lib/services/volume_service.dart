import 'dart:io';

import 'package:volume_controller/volume_controller.dart';

class VolumeService {
  static double volume = 0.5;
  static double pitch = 0.5;
  static double rate = Platform.isIOS ? 0.5 : 0.6;

  static void setMaximumVolume() {
    VolumeController().setVolume(1.0);
  }
}
