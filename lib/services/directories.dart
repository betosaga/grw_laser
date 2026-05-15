import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Directories {
  //
  //
  //
  static Directory? _temporaryDirectory;
  static Directory? _documentsDirectory;
  static Directory? _externalStorageDirectory;
  //
  //
  //
  static bool get isLoaded =>
      _temporaryDirectory != null && _documentsDirectory != null;
  //
  //
  //
  static String get tempPath => _temporaryDirectory?.path ?? "";
  static String get documentsPath => _documentsDirectory?.path ?? "";
  static String get externalStoragePath =>
      _externalStorageDirectory?.path ?? "";
  //
  //
  //
  static Directory get tempDir => _temporaryDirectory ?? Directory("");
  static Directory get documentsDir => _documentsDirectory ?? Directory("");
  static Directory get exteranlStorageDirectory =>
      _externalStorageDirectory ?? Directory("");
  //
  //
  //
  static Future<void> loadDirectory() async {
    _temporaryDirectory = await getTemporaryDirectory();
    _documentsDirectory = await getApplicationDocumentsDirectory();
    if (Platform.isAndroid) {
      _externalStorageDirectory = await getExternalStorageDirectory();
    }
  }
}
