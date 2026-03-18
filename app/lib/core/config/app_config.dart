import 'package:flutter/foundation.dart';

/// App-wide configuration for API base URLs.
class AppConfig {
  /// For Android emulator, localhost maps to 10.0.2.2
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:4000';

  /// Default base URL (desktop / web / physical device on same network)
  static const String defaultBaseUrl = 'http://localhost:4000';

  /// Returns the appropriate base URL for the current platform.
  static String get baseUrl {
    // On Android we assume emulator during debug; override in settings.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidEmulatorBaseUrl;
    }
    return defaultBaseUrl;
  }

  /// Hive box key where user can override base URL at runtime.
  static const String baseUrlOverrideKey = 'base_url_override';
}
