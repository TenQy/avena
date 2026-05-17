import 'package:drift/drift.dart';

import '../../../core/constants/app_roles.dart';
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
    final cleanPhone = phone?.trim();

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

    await _database.usersDao.insertUser(
      UsersCompanion.insert(
        id: IdGenerator.create(),
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
    final cleanPhone = phone?.trim();

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

    return UserActionResult.success;
  }

  Future<bool> _isUsernameTaken(
    String username, {
    String? excludingUserId,
  }) async {
    final existingUser = await _database.usersDao.getUserByUsername(username);

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
      return actor.role == AppRoles.superadmin &&
          nextRole == AppRoles.superadmin;
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
    return actor.role == AppRoles.superadmin &&
        actor.id != target.id &&
        target.role != AppRoles.superadmin;
  }
}
