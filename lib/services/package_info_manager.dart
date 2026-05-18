import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoManager {
  static String version = "";
  static String appName = "";
  static String packageName = "";
  static String buildNumber = "";
  static String appversion = "";
  static String device_id = "";
  static String imei = "";
  static String meid = "";

  static Future<void> loadInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
    appversion = "$version+$buildNumber";

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosDeviceInfo = await deviceInfo.iosInfo;
      device_id = iosDeviceInfo.identifierForVendor ?? ""; // unique ID on iOS
    } else if (Platform.isAndroid) {
      device_id = await AndroidId().getId() ?? "";
    }
  }
}
