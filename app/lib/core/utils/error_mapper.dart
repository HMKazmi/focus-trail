import 'package:dio/dio.dart';

/// Maps Dio errors to user-friendly messages.
String mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out. Check your network.';
    case DioExceptionType.connectionError:
      return 'Could not connect to the server.';
    case DioExceptionType.badResponse:
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
      return 'Server error (${e.response?.statusCode ?? 'unknown'}).';
    case DioExceptionType.cancel:
      return 'Request cancelled.';
    default:
      return 'Unexpected network error.';
  }
}
