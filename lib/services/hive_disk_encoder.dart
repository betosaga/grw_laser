import 'package:hive_flutter/hive_flutter.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/services/data_disk_encoder.dart';

class HiveDiskEncoder implements DataDiskEncoder {
  final Box box;

  HiveDiskEncoder() : box = Hive.box(Constants.HIVE_BOX_NAME);

  @override
  bool? boolFor({required String key}) {
    final value = box.get(key);
    return value is bool ? value : null;
  }

  @override
  double? doubleFor({required String key}) {
    final value = box.get(key);
    return value is double ? value : null;
  }

  @override
  int? integerFor({required String key}) {
    final value = box.get(key);
    return value is int ? value : null;
  }

  @override
  String? stringFor({required String key}) {
    final value = box.get(key);
    return value is String ? value : null;
  }

  @override
  void setBoolean({required bool? value, required String key}) {
    box.put(key, value);
  }

  @override
  void setDouble({required double? value, required String key}) {
    box.put(key, value);
  }

  @override
  void setInt({required int? value, required String key}) {
    box.put(key, value);
  }

  @override
  void setString({required String? value, required String key}) {
    box.put(key, value);
  }

  @override
  Future<void> eraseKey({required String key}) async {
    return await box.delete(key);
  }

  @override
  Future<int> eraseAllKeys() async {
    return box.clear();
  }
}
