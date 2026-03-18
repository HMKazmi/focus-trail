import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/app_config.dart';
import '../storage/hive_boxes.dart';
import '../utils/logger.dart';

final dioProvider = Provider<Dio>((ref) {
  return createDio();
});

Dio createDio() {
  final settingsBox = Hive.box(HiveBoxes.settings);
  final overrideUrl = settingsBox.get(AppConfig.baseUrlOverrideKey) as String?;
  final baseUrl = (overrideUrl != null && overrideUrl.isNotEmpty)
      ? overrideUrl
      : AppConfig.baseUrl;

  AppLogger.info('Creating Dio client', module: 'Network', data: {'baseUrl': baseUrl});

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // Logging interceptor - logs all requests and responses
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final startTime = DateTime.now();
      options.extra['startTime'] = startTime;
      
      AppLogger.request(
        options.method,
        '${options.baseUrl}${options.path}',
        data: options.data is Map ? options.data as Map<String, dynamic> : null,
        headers: options.headers.map((key, value) => MapEntry(key, value.toString())),
      );
      
      // Log cURL command
      AppLogger.curl(
        options.method,
        '${options.baseUrl}${options.path}',
        data: options.data is Map ? options.data as Map<String, dynamic> : null,
        headers: options.headers.map((key, value) => MapEntry(key, value.toString())),
        queryParameters: options.queryParameters,
      );
      
      handler.next(options);
    },
    onResponse: (response, handler) {
      final startTime = response.requestOptions.extra['startTime'] as DateTime?;
      final duration = startTime != null 
          ? DateTime.now().difference(startTime).inMilliseconds 
          : null;
      
      AppLogger.response(
        response.requestOptions.method,
        '${response.requestOptions.baseUrl}${response.requestOptions.path}',
        response.statusCode ?? 0,
        data: response.data,
        duration: duration,
      );
      
      handler.next(response);
    },
    onError: (error, handler) {
      final startTime = error.requestOptions.extra['startTime'] as DateTime?;
      final duration = startTime != null 
          ? DateTime.now().difference(startTime).inMilliseconds 
          : null;
      
      AppLogger.error(
        'Network request failed: ${error.message}',
        module: 'Network',
        error: {
          'method': error.requestOptions.method,
          'url': '${error.requestOptions.baseUrl}${error.requestOptions.path}',
          'statusCode': error.response?.statusCode,
          'duration': duration,
          'response': error.response?.data,
        },
      );
      
      handler.next(error);
    },
  ));

  // Auth interceptor – attaches Bearer token from Hive
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final authBox = Hive.box(HiveBoxes.auth);
      final token = authBox.get('token') as String?;
      if (token != null) {
        AppLogger.debug('Attaching auth token to request: $token', module: 'Network');
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        AppLogger.debug('No auth token available', module: 'Network');
      }
      handler.next(options);
    },
    onError: (error, handler) {
      handler.next(error);
    },
  ));

  AppLogger.success('Dio client created successfully', module: 'Network');
  return dio;
}
