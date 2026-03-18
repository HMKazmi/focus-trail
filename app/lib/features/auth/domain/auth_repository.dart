import '../../../core/utils/result.dart';
import 'entities/user_entity.dart';

/// Auth repository contract.
abstract class AuthRepository {
  Future<Result<({String token, UserEntity user})>> login(String email, String password);
  Future<Result<({String token, UserEntity user})>> register(String email, String password, String name);
  Future<void> logout();
  String? getStoredToken();
  UserEntity? getStoredUser();
}
