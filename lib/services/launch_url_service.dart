import 'dart:io';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:url_launcher/url_launcher_string.dart';

class LaunchUrlService {
  static Future<void> launch(String url) async {
    try {
      if (Platform.isIOS) {
        final UrlLauncherPlatform launcher = UrlLauncherPlatform.instance;
        if (await launcher.canLaunch(url)) {
          await launcher.launch(
            url,
            useSafariVC: false,
            useWebView: false,
            enableJavaScript: false,
            enableDomStorage: false,
            universalLinksOnly: false,
            headers: <String, String>{},
          );
        } else {
          throw Exception('Could not launch $url');
        }
      } else {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
