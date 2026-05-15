import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final bipSingoloSound = AssetSource("bip_singolo.mp3");
  static final laserActivationSound = AssetSource("laser_activation_sound.mp3");
  static final laserDeactivationSound =
      AssetSource("laser_deactivation_sound.mp3");
  static final beepStop = AssetSource("beepStop.mp3");
  static final beepOk = AssetSource("beepOK.mp3");
  static final player = AudioPlayer();

  static Future<void> playLaserActivationSound() async {
    await player.play(laserActivationSound);
  }

  static Future<void> playBipSingoloSound() async {
    await player.play(bipSingoloSound);
  }

  static Future<void> playLaserDectivationSound() async {
    await player.play(laserDeactivationSound);
  }

  static Future<void> playBeepStop() async {
    await player.play(beepStop);
  }

  static Future<void> playBeepOk() async {
    await player.play(beepOk);
  }

  static Future<void> stopPlayer() async {
    await player.stop();
  }
}
