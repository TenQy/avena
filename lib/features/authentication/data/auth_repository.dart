import 'package:drift/drift.dart';

import '../../../core/constants/app_activity_logs.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';
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
    final user = await _database.usersDao.getVisibleUserByUsername(
      username.trim(),
    );

    if (user == null || user.passwordHash != password) {
      return const LoginResponse(LoginResult.invalidCredentials);
    }

    if (!user.isActive || user.isDeleted) {
      await _localSource.clearCurrentUserId();
      return const LoginResponse(LoginResult.inactiveUser);
    }

    await _localSource.saveCurrentUserId(user.id);
    final now = DateTime.now();
    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(user.id),
        userNameSnapshot: user.username,
        userRoleSnapshot: user.role,
        action: AppActivityLogActions.login,
        entityType: AppActivityLogEntities.session,
        description: const Value('Inicio de sesión exitoso'),
        createdAt: now,
        syncStatus: 'pending',
      ),
    );

    return LoginResponse(LoginResult.success, user: user);
  }

  Future<void> logout({required User? actor}) async {
    if (actor != null) {
      final now = DateTime.now();
      await _database.activityLogsDao.insertActivityLog(
        ActivityLogsCompanion.insert(
          id: IdGenerator.create(),
          userId: Value(actor.id),
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          action: AppActivityLogActions.logout,
          entityType: AppActivityLogEntities.session,
          description: const Value('Cierre de sesión manual'),
          createdAt: now,
          syncStatus: 'pending',
        ),
      );
    }

    await _localSource.clearCurrentUserId();
  }

  bool _canUseSession(User? user) {
    return user != null && user.isActive && !user.isDeleted;
  }
}

class LoginResponse {
  const LoginResponse(this.result, {this.user});

  final LoginResult result;
  final User? user;
}
