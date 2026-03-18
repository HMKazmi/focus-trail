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
      final statusCode = e.response?.statusCode;

      // Try to extract message from server response
      if (data is Map) {
        // Handle { success: false, error: { message: "..." } } format
        if (data.containsKey('error') && data['error'] is Map) {
          final error = data['error'] as Map;
          if (error.containsKey('message')) {
            return error['message'].toString();
          }
        }
        // Handle { message: "..." } format
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
      }

      // Provide friendly messages for common status codes
      switch (statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Invalid email or password.';
        case 403:
          return 'Access denied.';
        case 404:
          return 'Resource not found.';
        case 409:
          return 'This email is already registered.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Server error ($statusCode).';
      }
    case DioExceptionType.cancel:
      return 'Request cancelled.';
    default:
      return 'Unexpected network error.';
  }
}
