import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/services/hive_disk_encoder.dart';

class ListsStore {
  static final _box = HiveDiskEncoder();

  static Future<void> eraseAllData() async {
    await _box.eraseKey(key: Constants.STORED_APP_DATA_KEY);
  }
}
