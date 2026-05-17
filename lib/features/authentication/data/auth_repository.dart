import '../../../core/database/app_database.dart';
import 'auth_local_source.dart';

enum LoginResult { success, invalidCredentials, inactiveUser }

class AuthRepository {
  AuthRepository(this._database, this._localSource);

  final AppDatabase _database;
  final AuthLocalSource _localSource;

  Future<User?> restoreSession() async {
    final userId = await _localSource.readCurrentUserId();

    if (userId == null) {
      return null;
    }

    final user = await _database.usersDao.getUserById(userId);

    if (!_canUseSession(user)) {
      await _localSource.clearCurrentUserId();
      return null;
    }

    return user;
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final user = await _database.usersDao.getUserByUsername(username.trim());

    if (user == null || user.passwordHash != password) {
      return const LoginResponse(LoginResult.invalidCredentials);
    }

    if (!user.isActive || user.isDeleted) {
      await _localSource.clearCurrentUserId();
      return const LoginResponse(LoginResult.inactiveUser);
    }

    await _localSource.saveCurrentUserId(user.id);

    return LoginResponse(LoginResult.success, user: user);
  }

  Future<void> logout() => _localSource.clearCurrentUserId();

  bool _canUseSession(User? user) {
    return user != null && user.isActive && !user.isDeleted;
  }
}

class LoginResponse {
  const LoginResponse(this.result, {this.user});

  final LoginResult result;
  final User? user;
}
