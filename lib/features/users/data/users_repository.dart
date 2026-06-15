import 'package:drift/drift.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/constants/app_activity_logs.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';

enum UserSaveResult { success, forbidden, invalidRole, usernameTaken, notFound }

enum UserActionResult { success, forbidden, notFound }

class UsersRepository {
  UsersRepository(this._database);

  final AppDatabase _database;

  static const _pendingSync = 'pending';

  Stream<List<User>> watchActiveUsers() {
    return _database.usersDao.watchVisibleUsers();
  }

  Future<UserSaveResult> createUser({
    required User actor,
    required String username,
    required String password,
    required String role,
    String? phone,
  }) async {
    final cleanUsername = username.trim();
    final cleanPhone = _normalizePhone(phone);

    if (!AppRoles.isValid(role)) {
      return UserSaveResult.invalidRole;
    }

    if (!_canCreateRole(actor.role, role)) {
      return UserSaveResult.forbidden;
    }

    if (await _isUsernameTaken(cleanUsername)) {
      return UserSaveResult.usernameTaken;
    }

    final now = DateTime.now();
    final userId = IdGenerator.create();

    await _database.usersDao.insertUser(
      UsersCompanion.insert(
        id: userId,
        username: cleanUsername,
        passwordHash: password.trim(),
        role: role,
        phone: Value(
          cleanPhone == null || cleanPhone.isEmpty ? null : cleanPhone,
        ),
        createdAt: now,
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.createUser,
        entityType: AppActivityLogEntities.user,
        entityId: Value(userId),
        description: Value('Usuario creado: $cleanUsername ($role)'),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return UserSaveResult.success;
  }

  Future<UserSaveResult> updateUser({
    required User actor,
    required User target,
    required String username,
    required String role,
    String? password,
    String? phone,
  }) async {
    final currentTarget = await _database.usersDao.getUserById(target.id);

    if (currentTarget == null || currentTarget.isDeleted) {
      return UserSaveResult.notFound;
    }

    if (!AppRoles.isValid(role)) {
      return UserSaveResult.invalidRole;
    }

    if (!_canEditUser(actor, currentTarget, role)) {
      return UserSaveResult.forbidden;
    }

    final cleanUsername = username.trim();
    final cleanPhone = _normalizePhone(phone);
    final roleChanged = currentTarget.role != role;
    final usernameChanged = currentTarget.username != cleanUsername;

    if (await _isUsernameTaken(cleanUsername, excludingUserId: target.id)) {
      return UserSaveResult.usernameTaken;
    }

    final cleanPassword = password?.trim();

    await _database.usersDao.updateUser(
      currentTarget.copyWith(
        username: cleanUsername,
        passwordHash: cleanPassword == null || cleanPassword.isEmpty
            ? currentTarget.passwordHash
            : cleanPassword,
        role: role,
        phone: Value(
          cleanPhone == null || cleanPhone.isEmpty ? null : cleanPhone,
        ),
        updatedAt: DateTime.now(),
        syncStatus: _pendingSync,
      ),
    );

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.updateUser,
        entityType: AppActivityLogEntities.user,
        entityId: Value(currentTarget.id),
        description: Value(
          'Usuario actualizado: ${currentTarget.username}'
          '${usernameChanged ? ' -> $cleanUsername' : ''}'
          '${roleChanged ? ' ($role)' : ''}',
        ),
        createdAt: DateTime.now(),
        syncStatus: _pendingSync,
      ),
    );

    return UserSaveResult.success;
  }

  Future<UserActionResult> setUserActive({
    required User actor,
    required User target,
    required bool isActive,
  }) async {
    final currentTarget = await _database.usersDao.getUserById(target.id);

    if (currentTarget == null || currentTarget.isDeleted) {
      return UserActionResult.notFound;
    }

    if (!_canChangeUserState(actor, currentTarget)) {
      return UserActionResult.forbidden;
    }

    await _database.usersDao.updateUser(
      currentTarget.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
        syncStatus: _pendingSync,
      ),
    );

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.setUserActive,
        entityType: AppActivityLogEntities.user,
        entityId: Value(currentTarget.id),
        description: Value(
          isActive
              ? 'Usuario habilitado: ${currentTarget.username}'
              : 'Usuario inhabilitado: ${currentTarget.username}',
        ),
        createdAt: DateTime.now(),
        syncStatus: _pendingSync,
      ),
    );

    return UserActionResult.success;
  }

  Future<UserActionResult> deleteUser({
    required User actor,
    required User target,
  }) async {
    final currentTarget = await _database.usersDao.getUserById(target.id);

    if (currentTarget == null || currentTarget.isDeleted) {
      return UserActionResult.notFound;
    }

    if (!_canDeleteUser(actor, currentTarget)) {
      return UserActionResult.forbidden;
    }

    final now = DateTime.now();

    await _database.usersDao.updateUser(
      currentTarget.copyWith(
        isActive: false,
        isDeleted: true,
        deletedAt: Value(now),
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.deleteUser,
        entityType: AppActivityLogEntities.user,
        entityId: Value(currentTarget.id),
        description: Value('Usuario eliminado: ${currentTarget.username}'),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return UserActionResult.success;
  }

  Future<bool> _isUsernameTaken(
    String username, {
    String? excludingUserId,
  }) async {
    final existingUser = await _database.usersDao.getVisibleUserByUsername(
      username,
    );

    return existingUser != null &&
        !existingUser.isDeleted &&
        existingUser.id != excludingUserId;
  }

  bool _canCreateRole(String actorRole, String targetRole) {
    if (actorRole == AppRoles.superadmin) {
      return targetRole == AppRoles.admin || targetRole == AppRoles.employee;
    }

    return actorRole == AppRoles.admin && targetRole == AppRoles.employee;
  }

  bool _canEditUser(User actor, User target, String nextRole) {
    if (actor.id == target.id) {
      return actor.role == target.role && nextRole == target.role;
    }

    if (actor.role == AppRoles.superadmin) {
      return target.role != AppRoles.superadmin &&
          (nextRole == AppRoles.admin || nextRole == AppRoles.employee);
    }

    return actor.role == AppRoles.admin &&
        target.role == AppRoles.employee &&
        nextRole == AppRoles.employee;
  }

  bool _canChangeUserState(User actor, User target) {
    if (actor.id == target.id || target.role == AppRoles.superadmin) {
      return false;
    }

    if (actor.role == AppRoles.superadmin) {
      return true;
    }

    return actor.role == AppRoles.admin && target.role == AppRoles.employee;
  }

  bool _canDeleteUser(User actor, User target) {
    if (actor.id == target.id || target.role == AppRoles.superadmin) {
      return false;
    }

    if (actor.role == AppRoles.superadmin) {
      return true;
    }

    return actor.role == AppRoles.admin && target.role == AppRoles.employee;
  }

  String? _normalizePhone(String? phone) {
    final digits = phone?.replaceAll(RegExp(r'\D'), '');
    if (digits == null || digits.isEmpty) {
      return null;
    }

    return _formatPhone(digits.length <= 10 ? digits : digits.substring(0, 10));
  }

  String _formatPhone(String digits) {
    if (digits.length <= 2) {
      return digits;
    }

    if (digits.length <= 6) {
      return '${digits.substring(0, 2)} ${digits.substring(2)}';
    }

    return '${digits.substring(0, 2)} ${digits.substring(2, 6)} ${digits.substring(6)}';
  }
}
