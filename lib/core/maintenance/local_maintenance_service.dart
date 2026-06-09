import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_activity_logs.dart';
import '../constants/app_roles.dart';
import '../database/app_database.dart';
import '../storage/app_files.dart';
import '../utils/id_generator.dart';

class LocalMaintenanceService {
  LocalMaintenanceService(this._database);

  final AppDatabase _database;

  Future<BackupResult> exportLocalBackup({required User actor}) async {
    _ensureSuperadmin(actor);
    await _database.customStatement('PRAGMA wal_checkpoint(FULL)');

    final backupDir = await _createBackupDirectory();
    final databaseFiles = await _databaseFiles();

    for (final file in databaseFiles) {
      if (await file.exists()) {
        await file.copy(p.join(backupDir.path, p.basename(file.path)));
      }
    }

    final settingsFile = await AppFiles.settingsFile();
    if (await settingsFile.exists()) {
      await settingsFile.copy(
        p.join(backupDir.path, p.basename(settingsFile.path)),
      );
    }

    await _insertMaintenanceLog(
      actor: actor,
      action: AppActivityLogActions.exportBackup,
      description: 'Respaldo local exportado',
    );

    return BackupResult(path: backupDir.path);
  }

  Future<BackupResult> restoreLatestBackup({required User actor}) async {
    _ensureSuperadmin(actor);
    final latestBackup = await _latestBackupDirectory();

    if (latestBackup == null) {
      throw const MaintenanceException('No hay respaldos locales disponibles.');
    }

    await _database.close();

    final currentDatabaseFiles = await _databaseFiles();
    for (final file in currentDatabaseFiles) {
      if (await file.exists()) {
        await file.delete();
      }
    }

    final backupFiles = latestBackup.listSync().whereType<File>();
    for (final file in backupFiles) {
      final fileName = p.basename(file.path);
      if (_isDatabaseFile(fileName)) {
        final appDir = await getApplicationDocumentsDirectory();
        await file.copy(p.join(appDir.path, fileName));
      }
    }

    final backupSettingsFile = File(
      p.join(latestBackup.path, AppFiles.settingsFileName),
    );
    if (await backupSettingsFile.exists()) {
      final currentSettingsFile = await AppFiles.settingsFile();
      await backupSettingsFile.copy(currentSettingsFile.path);
    }

    return BackupResult(path: latestBackup.path);
  }

  Future<void> resetOperationalData({required User actor}) async {
    _ensureSuperadmin(actor);

    await _database.transaction(() async {
      await _database.delete(_database.pendingPaymentEntries).go();
      await _database.delete(_database.pendingPayments).go();
      await _database.delete(_database.salePayments).go();
      await _database.delete(_database.saleItems).go();
      await _database.delete(_database.sales).go();
      await _database.delete(_database.cashMovements).go();
      await _database.delete(_database.cashSessions).go();
      await _database.delete(_database.employeeSessions).go();
      await _database.delete(_database.syncQueue).go();
      await _insertMaintenanceLog(
        actor: actor,
        action: AppActivityLogActions.resetOperationalData,
        description: 'Datos operativos reiniciados conservando inventario',
      );
    });
  }

  Future<void> clearActivityLogs({required User actor}) async {
    _ensureSuperadmin(actor);

    await _database.transaction(() async {
      await _database.delete(_database.activityLogs).go();
      await _insertMaintenanceLog(
        actor: actor,
        action: AppActivityLogActions.clearLogs,
        description: 'Logs locales limpiados por superadmin',
      );
    });
  }

  Future<void> clearSyncQueue({required User actor}) async {
    _ensureSuperadmin(actor);

    await _database.transaction(() async {
      await _database.delete(_database.syncQueue).go();
      await _insertMaintenanceLog(
        actor: actor,
        action: AppActivityLogActions.clearSyncQueue,
        description: 'Cola de sincronizacion local limpiada',
      );
    });
  }

  Future<void> resetApplicationData({required User actor}) async {
    _ensureSuperadmin(actor);

    await _database.transaction(() async {
      await _database.delete(_database.pendingPaymentEntries).go();
      await _database.delete(_database.pendingPayments).go();
      await _database.delete(_database.salePayments).go();
      await _database.delete(_database.saleItems).go();
      await _database.delete(_database.sales).go();
      await _database.delete(_database.cashMovements).go();
      await _database.delete(_database.cashSessions).go();
      await _database.delete(_database.employeeSessions).go();
      await _database.delete(_database.activityLogs).go();
      await _database.delete(_database.syncQueue).go();
      await _database.delete(_database.products).go();
      await _database.delete(_database.subcategories).go();
      await _database.delete(_database.categories).go();
      await _database.delete(_database.users).go();

      final now = DateTime.now();

      await _database
          .into(_database.categories)
          .insert(
            CategoriesCompanion.insert(
              id: IdGenerator.create(),
              name: 'General',
              createdAt: now,
              updatedAt: now,
              syncStatus: 'synced',
            ),
          );

      await _database
          .into(_database.users)
          .insert(
            UsersCompanion.insert(
              id: actor.id,
              username: actor.username,
              passwordHash: actor.passwordHash,
              role: AppRoles.superadmin,
              isActive: const Value(true),
              phone: Value(actor.phone),
              createdAt: actor.createdAt,
              updatedAt: now,
              deletedAt: const Value(null),
              isDeleted: const Value(false),
              syncStatus: 'synced',
            ),
          );
    });

    final settingsFile = await AppFiles.settingsFile();
    if (await settingsFile.exists()) {
      await settingsFile.delete();
    }

    await _keepOnlyLatestBackup();
  }

  Future<void> _insertMaintenanceLog({
    required User actor,
    required String action,
    required String description,
  }) {
    final now = DateTime.now();

    return _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: action,
        entityType: AppActivityLogEntities.maintenance,
        description: Value(description),
        createdAt: now,
        syncStatus: 'pending',
      ),
    );
  }

  Future<Directory> _createBackupDirectory() async {
    final root = await AppFiles.backupDirectory();
    if (!await root.exists()) {
      await root.create(recursive: true);
    }

    final directory = Directory(p.join(root.path, _timestamp()));
    await directory.create(recursive: true);

    return directory;
  }

  Future<Directory?> _latestBackupDirectory() async {
    final root = await AppFiles.backupDirectory();
    if (!await root.exists()) {
      return null;
    }

    final backups = root.listSync().whereType<Directory>().toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    return backups.isEmpty ? null : backups.first;
  }

  Future<void> _keepOnlyLatestBackup() async {
    final root = await AppFiles.backupDirectory();
    if (!await root.exists()) {
      return;
    }

    final backups = root.listSync().whereType<Directory>().toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    if (backups.length <= 1) {
      return;
    }

    for (final backup in backups.skip(1)) {
      await backup.delete(recursive: true);
    }
  }

  Future<List<File>> _databaseFiles() async {
    final databaseFile = await AppFiles.databaseFile();

    return [
      databaseFile,
      File('${databaseFile.path}-wal'),
      File('${databaseFile.path}-shm'),
    ];
  }

  bool _isDatabaseFile(String fileName) {
    return fileName == AppFiles.databaseFileName ||
        fileName == '${AppFiles.databaseFileName}-wal' ||
        fileName == '${AppFiles.databaseFileName}-shm';
  }

  String _timestamp() {
    final now = DateTime.now();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return [
      now.year.toString(),
      twoDigits(now.month),
      twoDigits(now.day),
      '_',
      twoDigits(now.hour),
      twoDigits(now.minute),
      twoDigits(now.second),
    ].join();
  }

  void _ensureSuperadmin(User actor) {
    if (actor.role != AppRoles.superadmin) {
      throw const MaintenanceException(
        'Solo superadmin puede usar mantenimiento.',
      );
    }
  }
}

class BackupResult {
  const BackupResult({required this.path});

  final String path;
}

class MaintenanceException implements Exception {
  const MaintenanceException(this.message);

  final String message;
}
