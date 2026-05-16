import 'package:drift/drift.dart';

import '../utils/id_generator.dart';
import 'app_database.dart';

class DatabaseSeed {
  const DatabaseSeed._();

  static const _synced = 'synced';
  static const _superadminRole = 'superadmin';
  static const _superadminUsername = 'superadmin';
  static const _initialPasswordHash = 'initial-superadmin-password';

  static Future<void> ensureInitialData(AppDatabase database) async {
    await database.transaction(() async {
      await _ensureGeneralCategory(database);
      await _ensureSuperadmin(database);
    });
  }

  static Future<void> _ensureGeneralCategory(AppDatabase database) async {
    final existingCategory =
        await (database.select(database.categories)
              ..where((category) => category.name.equals('General'))
              ..limit(1))
            .getSingleOrNull();

    if (existingCategory != null) {
      return;
    }

    final now = DateTime.now();

    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: IdGenerator.create(),
            name: 'General',
            createdAt: now,
            updatedAt: now,
            syncStatus: _synced,
          ),
        );
  }

  static Future<void> _ensureSuperadmin(AppDatabase database) async {
    final existingSuperadmin =
        await (database.select(database.users)
              ..where(
                (user) =>
                    user.role.equals(_superadminRole) &
                    user.isDeleted.equals(false),
              )
              ..limit(1))
            .getSingleOrNull();

    if (existingSuperadmin != null) {
      return;
    }

    final now = DateTime.now();

    await database
        .into(database.users)
        .insert(
          UsersCompanion.insert(
            id: IdGenerator.create(),
            username: _superadminUsername,
            passwordHash: _initialPasswordHash,
            role: _superadminRole,
            createdAt: now,
            updatedAt: now,
            syncStatus: _synced,
          ),
        );
  }
}
