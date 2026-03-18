import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';
import 'hive_boxes.dart';

/// Opens all Hive boxes used by the app.
Future<void> openHiveBoxes() async {
  AppLogger.storage('Opening box', HiveBoxes.auth);
  await Hive.openBox(HiveBoxes.auth);
  AppLogger.success('Box opened: ${HiveBoxes.auth}', module: 'Hive');
  
  AppLogger.storage('Opening box', HiveBoxes.tasks);
  await Hive.openBox<Map>(HiveBoxes.tasks);
  AppLogger.success('Box opened: ${HiveBoxes.tasks}', module: 'Hive');
  
  AppLogger.storage('Opening box', HiveBoxes.syncQueue);
  await Hive.openBox<Map>(HiveBoxes.syncQueue);
  AppLogger.success('Box opened: ${HiveBoxes.syncQueue}', module: 'Hive');
  
  AppLogger.storage('Opening box', HiveBoxes.settings);
  await Hive.openBox(HiveBoxes.settings);
  AppLogger.success('Box opened: ${HiveBoxes.settings}', module: 'Hive');
  
  AppLogger.separator();
}
