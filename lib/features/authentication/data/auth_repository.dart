import '../../../core/database/app_database.dart';

enum LoginResult { success, invalidCredentials, inactiveUser }

class AuthRepository {
  AuthRepository(this._database);

  final AppDatabase _database;

  Future<LoginResult> validateCredentials({
    required String username,
    required String password,
  }) async {
    final user = await _database.usersDao.getUserByUsername(username.trim());

    if (user == null || user.passwordHash != password) {
      return LoginResult.invalidCredentials;
    }

    if (!user.isActive || user.isDeleted) {
      return LoginResult.inactiveUser;
    }

    return LoginResult.success;
  }
}
