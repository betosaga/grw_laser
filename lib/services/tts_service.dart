import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:grw_laser/model/tss_state.dart';
import 'package:grw_laser/services/language_manager.dart';
import 'package:grw_laser/services/volume_service.dart';

class TTSService {
  static FlutterTts flutterTts = FlutterTts();
  static TtsState ttsState = TtsState.stopped;

  static Future<void> init() async {
    flutterTts = FlutterTts();
    await _getLanguages();
    if (Platform.isAndroid) {
      await _getEngines();
    }
  }

  static Future<void> speak(String errormessage) async {
    await flutterTts.setVolume(VolumeService.volume);
    await flutterTts.setSpeechRate(VolumeService.rate);
    await flutterTts.setPitch(VolumeService.pitch);
    if (errormessage.isNotEmpty) {
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(errormessage);
    }
  }

  static Future<void> _getLanguages() async {
    LanguageManager.languages = await flutterTts.getLanguages;
    if (LanguageManager.languages != null) {
      // mySetState(() => LanguageManager.languages);
    }
  }

  static Future<void> _getEngines() async {
    final engines = await flutterTts.getEngines;
    if (engines != null) {
      for (dynamic engine in engines) {
        print(engine);
      }
    }
  }

  static Future<void> stop() async {
    await flutterTts.stop();
  }
}
