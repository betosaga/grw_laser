import 'package:grw_laser/configuration/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Preferences belong to the tablet and survive logout and app restarts.
class GeneralSettings {
  static String _normalize(dynamic value) => value == 'SCAN' ? 'SCAN' : 'FLAT';

  static String get robotSearchMode => _normalize(Constants.ROBOT_SEARCH_MODE);

  /// Called after opening Hive and before building the application.
  static void restore() {
    Constants.ROBOT_SEARCH_MODE = _normalize(
      Hive.box(
        Constants.HIVE_BOX_NAME,
      ).get(Constants.HIVE_ROBOT_SEARCH_MODE_KEY),
    );
  }

  static Future<void> setRobotSearchMode(String value) async {
    final mode = _normalize(value);
    await Hive.box(
      Constants.HIVE_BOX_NAME,
    ).put(Constants.HIVE_ROBOT_SEARCH_MODE_KEY, mode);
    Constants.ROBOT_SEARCH_MODE = mode;
  }
}
