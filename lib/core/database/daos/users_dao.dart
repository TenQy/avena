import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/users.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Stream<List<User>> watchUsers() => select(users).watch();

  Future<List<User>> getUsers() => select(users).get();

  Future<User?> getUserById(String id) {
    return (select(
      users,
    )..where((user) => user.id.equals(id))).getSingleOrNull();
  }

  Future<User?> getUserByUsername(String username) {
    return (select(
      users,
    )..where((user) => user.username.equals(username))).getSingleOrNull();
  }

  Future<User?> getSuperadmin() {
    return (select(users)
          ..where(
            (user) =>
                user.role.equals('superadmin') & user.isDeleted.equals(false),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> insertUser(UsersCompanion user) => into(users).insert(user);

  Future<bool> updateUser(UsersCompanion user) => update(users).replace(user);
}
