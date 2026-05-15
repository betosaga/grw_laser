import 'package:flutter/material.dart';
import 'package:grw_laser/configuration/constants.dart';
import 'package:grw_laser/grw_laser_app.dart';
import 'package:grw_laser/services/device_info_manager.dart';
import 'package:grw_laser/services/directories.dart';
import 'package:grw_laser/services/package_info_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(Constants.HIVE_BOX_NAME);
  await PackageInfoManager.loadInfo();
  await DeviceInfoManager.loadInfo();
  await Directories.loadDirectory();
  runApp(GrwLaserApp());
}
