import 'package:dio/dio.dart';

import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/result.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/user_entity.dart';
import 'datasource/auth_local_datasource.dart';
import 'datasource/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  AuthRepositoryImpl(this._remote, this._local);

  @override
  Future<Result<({String token, UserEntity user})>> login(String email, String password) async {
    try {
      final result = await _remote.login(email, password);
      _local.saveToken(result.token);
      _local.saveUser(result.user);
      return Result.success((token: result.token, user: result.user.toEntity()));
    } on DioException catch (e) {
      return Result.failure(mapDioError(e));
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<({String token, UserEntity user})>> register(String email, String password, String name) async {
    try {
      final result = await _remote.register(email, password, name);
      _local.saveToken(result.token);
      _local.saveUser(result.user);
      return Result.success((token: result.token, user: result.user.toEntity()));
    } on DioException catch (e) {
      return Result.failure(mapDioError(e));
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    _local.clear();
  }

  @override
  String? getStoredToken() => _local.getToken();

  @override
  UserEntity? getStoredUser() => _local.getUser()?.toEntity();
}
