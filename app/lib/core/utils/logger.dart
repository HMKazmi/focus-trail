import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Comprehensive logging utility for FocusTrail Flutter app
/// Provides structured, colored console logging for all operations

class AppLogger {
  static const String _reset = '\x1B[0m';
  static const String _bright = '\x1B[1m';
  static const String _dim = '\x1B[2m';
  
  // Colors
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';

  /// Log general information
  static void info(String message, {String? module, Map<String, dynamic>? data}) {
    _log('INFO', message, _cyan, module: module, data: data);
  }

  /// Log success messages
  static void success(String message, {String? module, Map<String, dynamic>? data}) {
    _log('SUCCESS', message, _green, module: module, data: data);
  }

  /// Log warnings
  static void warn(String message, {String? module, Map<String, dynamic>? data}) {
    _log('WARN', message, _yellow, module: module, data: data);
  }

  /// Log errors
  static void error(String message, {String? module, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, _red, module: module, error: error, stackTrace: stackTrace);
  }

  /// Log debug information (only in debug mode)
  static void debug(String message, {String? module, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      _log('DEBUG', message, _magenta, module: module, data: data);
    }
  }

  /// Log network requests
  static void request(String method, String url, {Map<String, dynamic>? data, Map<String, dynamic>? headers}) {
    _log('REQUEST', '$_bright$method$_reset $url', _blue, 
      module: 'Network',
      data: {
        if (data != null) 'body': data,
        if (headers != null) 'headers': headers,
      },
    );
  }

  /// Log cURL equivalent of a request
  static void curl(String method, String url, {Map<String, dynamic>? data, Map<String, String>? headers, Map<String, dynamic>? queryParameters}) {
    final curlCmd = _buildCurlCommand(method, url, data: data, headers: headers, queryParameters: queryParameters);
    if (kDebugMode) {
      print('\n$_bright$_cyan╔════════════════════════════════════════════════════════════════════════════════╗$_reset');
      print('$_bright$_cyan║ cURL Command                                                                   ║$_reset');
      print('$_bright$_cyan╚════════════════════════════════════════════════════════════════════════════════╝$_reset');
      print('$_green$curlCmd$_reset\n');
    }
  }

  static String _buildCurlCommand(String method, String url, {Map<String, dynamic>? data, Map<String, String>? headers, Map<String, dynamic>? queryParameters}) {
    final buffer = StringBuffer('curl -X $method');
    
    // Add headers
    if (headers != null && headers.isNotEmpty) {
      headers.forEach((key, value) {
        // Escape single quotes in header values
        final escapedValue = value.replaceAll("'", "'\\''");
        buffer.write(" \\\n  -H '$key: $escapedValue'");
      });
    }
    
    // Add request body
    if (data != null && data.isNotEmpty) {
      final jsonStr = _stringifyData(data);
      // Escape single quotes in JSON
      final escapedJson = jsonStr.replaceAll("'", "'\\''");
      buffer.write(" \\\n  -d '$escapedJson'");
    }
    
    // Add URL with query parameters
    String finalUrl = url;
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final queryString = queryParameters.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      finalUrl = '$url?$queryString';
    }
    
    buffer.write(" \\\n  '$finalUrl'");
    
    return buffer.toString();
  }

  static String _stringifyData(dynamic data) {
    if (data is Map) {
      final entries = data.entries.map((e) => '"${e.key}":${_stringifyData(e.value)}').join(',');
      return '{$entries}';
    } else if (data is List) {
      final items = data.map(_stringifyData).join(',');
      return '[$items]';
    } else if (data is String) {
      return '"$data"';
    } else if (data == null) {
      return 'null';
    } else {
      return data.toString();
    }
  }

  /// Log network responses
  static void response(String method, String url, int statusCode, {dynamic data, int? duration}) {
    final statusColor = statusCode >= 200 && statusCode < 300 ? _green :
                       statusCode >= 400 && statusCode < 500 ? _yellow : _red;
    final durationStr = duration != null ? ' ${_dim}(${duration}ms)$_reset' : '';
    
    _log('RESPONSE', '$_bright$method$_reset $url $statusColor$statusCode$_reset$durationStr', _green,
      module: 'Network',
      data: data != null ? {'response': data} : null,
    );
  }

  /// Log storage operations
  static void storage(String operation, String box, {Map<String, dynamic>? data}) {
    _log('STORAGE', '$operation → $_cyan$box$_reset', _yellow,
      module: 'Hive',
      data: data,
    );
  }

  /// Log sync operations
  static void sync(String operation, {Map<String, dynamic>? data}) {
    _log('SYNC', operation, _magenta,
      module: 'Sync',
      data: data,
    );
  }

  /// Log authentication operations
  static void auth(String action, {String? user, Map<String, dynamic>? data}) {
    final userStr = user != null ? ' → $_cyan$user$_reset' : '';
    _log('AUTH', '$action$userStr', _magenta,
      module: 'Auth',
      data: data,
    );
  }

  /// Log navigation
  static void navigation(String action, String route) {
    _log('NAV', '$action → $_cyan$route$_reset', _blue,
      module: 'Router',
    );
  }

  /// Log UI events
  static void ui(String event, {String? widget, Map<String, dynamic>? data}) {
    final widgetStr = widget != null ? ' [$_cyan$widget$_reset]' : '';
    _log('UI', '$event$widgetStr', _blue,
      module: 'UI',
      data: data,
    );
  }

  static void _log(
    String level,
    String message,
    String color, {
    String? module,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = '$color$_bright[$level]$_reset';
    final moduleStr = module != null ? '$_cyan[$module]$_reset' : '';
    final timeStr = '$_dim$timestamp$_reset';
    
    final logMessage = [timeStr, levelStr, moduleStr, message]
        .where((s) => s.isNotEmpty)
        .join(' ');

    // Use developer.log for better debugging in Flutter DevTools
    developer.log(
      logMessage,
      name: module ?? level,
      time: DateTime.now(),
      level: _getLogLevel(level),
    );

    // Also print to console for easier viewing
    if (kDebugMode) {
      print(logMessage);
      
      if (data != null && data.isNotEmpty) {
        print('$_dim  ↳ Data:$_reset');
        data.forEach((key, value) {
          print('$_dim    $key: $value$_reset');
        });
      }
      
      if (error != null) {
        print('$_red  ↳ Error: $error$_reset');
      }
      
      if (stackTrace != null) {
        print('$_dim  ↳ StackTrace:$_reset');
        print('$_dim${stackTrace.toString().split('\n').take(5).join('\n')}$_reset');
      }
    }
  }

  static int _getLogLevel(String level) {
    switch (level) {
      case 'ERROR':
        return 1000;
      case 'WARN':
        return 900;
      case 'INFO':
      case 'SUCCESS':
        return 800;
      case 'DEBUG':
        return 500;
      default:
        return 700;
    }
  }

  /// Print a separator line
  static void separator() {
    if (kDebugMode) {
      print('$_dim${'─' * 80}$_reset');
    }
  }

  /// Print app startup banner
  static void startupBanner() {
    if (kDebugMode) {
      print('\n');
      separator();
      print('$_bright$_green   ___                 _____           _ _ $_reset');
      print('$_bright$_green  / __\\__   ___ _   _/__   \\___ _ __ (_) |$_reset');
      print('$_bright$_green / _\\/ _ \\ / __| | | | / /\\/ _  |  _|| | |$_reset');
      print('$_bright$_green/ / | (_) | (__| |_| |/ / | |_| | |  | | |$_reset');
      print('$_bright$_green\\/   \\___/ \\___|\\__,_|\\/   \\__,_|_|  |_|_|$_reset');
      print('');
      print('$_bright${_cyan}🚀 FocusTrail Mobile App$_reset');
      print('${_dim}   Offline-First Productivity Tracker$_reset');
      print('');
      separator();
      print('\n');
    }
  }
}
