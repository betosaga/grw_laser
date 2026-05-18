import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoManager {
  static String version = "";
  static String appName = "";
  static String packageName = "";
  static String buildNumber = "";
  static String appversion = "";
  static bool isTablet = false;

  static Future<void> loadInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
    appversion = "$version+$buildNumber";
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // log(jsonEncode(androidInfo.systemFeatures));
      // Controllo 1: Se ha android.hardware.type.tablet
      if (androidInfo.systemFeatures.contains('android.hardware.type.tablet') ||
          androidInfo.systemFeatures
              .contains('com.samsung.feature.device_category_tablet')) {
        //
        isTablet = true;
      }

      // Controllo 2: Se NON ha telephony (tipico dei tablet)
      if (!androidInfo.systemFeatures.contains('android.hardware.telephony')) {
        isTablet = true;
      }
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;

      // Semplicemente controlla se il model contiene "iPad"
      isTablet = iosInfo.model.toLowerCase().contains('ipad');
    }
  }
}
