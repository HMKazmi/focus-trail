import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/datasource/auth_local_datasource.dart';
import '../../data/datasource/auth_remote_datasource.dart';
import '../../domain/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

// ── DI providers ────────────────────────────────────────────
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});

// ── Auth state ──────────────────────────────────────────────
class AuthState {
  final String? token;
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.token, this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    String? token,
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearToken = false,
  }) {
    return AuthState(
      token: clearToken ? null : (token ?? this.token),
      user: clearToken ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo)
      : super(AuthState(
          token: _repo.getStoredToken(),
          user: _repo.getStoredUser(),
        ));

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.login(email, password);
    return result.when(
      success: (data) {
        state = state.copyWith(token: data.token, user: data.user, isLoading: false);
        return true;
      },
      failure: (msg) {
        state = state.copyWith(isLoading: false, error: msg);
        return false;
      },
    );
  }

  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repo.register(email, password, name);
    return result.when(
      success: (data) {
        state = state.copyWith(token: data.token, user: data.user, isLoading: false);
        return true;
      },
      failure: (msg) {
        state = state.copyWith(isLoading: false, error: msg);
        return false;
      },
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
