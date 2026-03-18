import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/storage/hive_init.dart';
import 'core/utils/logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print startup banner
  AppLogger.startupBanner();
  AppLogger.info('Initializing FocusTrail App...', module: 'Bootstrap');

  try {
    AppLogger.info('Initializing Hive...', module: 'Bootstrap');
    await Hive.initFlutter();
    AppLogger.success('Hive initialized successfully', module: 'Bootstrap');

    AppLogger.info('Opening Hive boxes...', module: 'Bootstrap');
    await openHiveBoxes();
    AppLogger.success(
      'All Hive boxes opened successfully',
      module: 'Bootstrap',
    );

    AppLogger.success('App initialization complete! 🎉', module: 'Bootstrap');
    AppLogger.separator();
  } catch (e, stack) {
    AppLogger.error(
      'Failed to initialize app',
      module: 'Bootstrap',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }

  runApp(const ProviderScope(child: FocusTrailApp()));
}
