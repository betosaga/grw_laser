import 'package:vibration/vibration.dart';

//
//
//
//
class Vibrator {
  //
  //
  //
  //
  static Future<void> shortVibration() async {
    try {
      await Vibration.vibrate(duration: 100, amplitude: 225);
    } catch (e) {
      print(e.toString());
    }
  }

  //
  //
  //
  //
  static Future<void> mediumVibration() async {
    try {
      await Vibration.vibrate(duration: 400, amplitude: 225);
    } catch (e) {
      print(e.toString());
    }
  }

  //
  //
  //
  //
  static Future<void> longVibration() async {
    try {
      await Vibration.vibrate(duration: 600, amplitude: 255);
    } catch (e) {
      print(e.toString());
    }
  }
  //
  //
  //
  //
}
