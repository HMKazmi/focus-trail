import 'package:dio/dio.dart';

import '../../../../core/utils/logger.dart';
import '../dto/user_dto.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<({String token, UserDto user})> login(String email, String password) async {
    AppLogger.auth('Login request', user: email);
    
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final data = res.data['data'] as Map<String, dynamic>;
      final token = data['accessToken'] as String;
      final user = UserDto.fromJson(data['user'] as Map<String, dynamic>);
      
      AppLogger.success('Login successful', module: 'AuthRemote', data: {
        'userId': user.id,
        'email': user.email,
      });
      
      return (token: token, user: user);
    } catch (e, stack) {
      AppLogger.error('Login failed', module: 'AuthRemote', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<({String token, UserDto user})> register(String email, String password, String name) async {
    AppLogger.auth('Register request', user: email, data: {'name': name});
    
    try {
      final res = await _dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      
      final data = res.data['data'] as Map<String, dynamic>;
      final token = data['accessToken'] as String;
      final user = UserDto.fromJson(data['user'] as Map<String, dynamic>);
      
      AppLogger.success('Registration successful', module: 'AuthRemote', data: {
        'userId': user.id,
        'email': user.email,
      });
      
      return (token: token, user: user);
    } catch (e, stack) {
      AppLogger.error('Registration failed', module: 'AuthRemote', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
