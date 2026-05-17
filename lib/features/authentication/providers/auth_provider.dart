import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/auth_local_source.dart';
import '../data/auth_repository.dart';

final authLocalSourceProvider = Provider<AuthLocalSource>((ref) {
  return const AuthLocalSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(databaseProvider),
    ref.watch(authLocalSourceProvider),
  );
});

final authProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthState>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

final currentUserProvider = Provider<AsyncValue<User?>>((ref) {
  return ref.watch(authProvider).whenData((state) => state.user);
});

class AuthController extends StateNotifier<AsyncValue<AuthState>> {
  AuthController(this._repository) : super(const AsyncValue.loading()) {
    restoreSession();
  }

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = await _repository.restoreSession();

      return AuthState(user: user);
    });
  }

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final response = await _repository.login(
      username: username,
      password: password,
    );

    if (response.result == LoginResult.success) {
      state = AsyncValue.data(AuthState(user: response.user));
    }

    return response.result;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(AuthState());
  }
}

class AuthState {
  const AuthState({this.user});

  final User? user;

  bool get isAuthenticated => user != null;
}
