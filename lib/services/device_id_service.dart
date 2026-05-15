import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceIdService {
  static final deviceInfo = DeviceInfoPlugin();

  static Future<String?> getDeviceID() async {
    if (Platform.isIOS) {
      final iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else if (Platform.isAndroid) {
      return AndroidId().getId(); // unique ID on Android
    }
    return null;
  }
}
