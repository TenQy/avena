import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
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

  static const _backupVersion = 1;
  static const _backupExtension = '.zip';
  static const _manifestFileName = 'manifest.json';

  Future<BackupResult> createShareableBackup({required User actor}) async {
    _ensureSuperadmin(actor);
    await _database.customStatement('PRAGMA wal_checkpoint(FULL)');

    final backupDir = await _createBackupDirectory();
    final databaseFiles = await _databaseFiles();
    final includedFiles = <String>[];

    for (final file in databaseFiles) {
      if (await file.exists()) {
        final fileName = p.basename(file.path);
        includedFiles.add(fileName);
        await file.copy(p.join(backupDir.path, fileName));
      }
    }

    final settingsFile = await AppFiles.settingsFile();
    if (await settingsFile.exists()) {
      includedFiles.add(AppFiles.settingsFileName);
      await settingsFile.copy(
        p.join(backupDir.path, AppFiles.settingsFileName),
      );
    }

    final manifest = {
      'app': 'tienda',
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'files': includedFiles,
    };
    await File(
      p.join(backupDir.path, _manifestFileName),
    ).writeAsString(jsonEncode(manifest));

    final packageFile = File(
      p.join(
        (await AppFiles.backupDirectory()).path,
        'tienda_respaldo_${_timestamp()}$_backupExtension',
      ),
    );
    final encoder = ZipFileEncoder();
    encoder.create(packageFile.path, level: ZipFileEncoder.gzip);
    await encoder.addDirectory(
      backupDir,
      includeDirName: false,
      level: ZipFileEncoder.gzip,
    );
    await encoder.close();

    await _insertMaintenanceLog(
      actor: actor,
      action: AppActivityLogActions.exportBackup,
      description: 'Respaldo compartible creado',
    );

    return BackupResult(path: packageFile.path);
  }

  Future<BackupResult> restoreBackupPackage({
    required User actor,
    required String packagePath,
  }) async {
    _ensureSuperadmin(actor);

    final packageFile = File(packagePath);
    if (!await packageFile.exists()) {
      throw const MaintenanceException('No se encontró el respaldo.');
    }

    final archive = ZipDecoder().decodeBytes(await packageFile.readAsBytes());
    final manifestFile = archive.findFile(_manifestFileName);
    if (manifestFile == null) {
      throw const MaintenanceException('El archivo no es un respaldo valido.');
    }

    final manifest = jsonDecode(utf8.decode(manifestFile.content));
    if (manifest is! Map ||
        manifest['app'] != 'tienda' ||
        manifest['version'] != _backupVersion) {
      throw const MaintenanceException('El respaldo no es compatible.');
    }

    if (archive.findFile(AppFiles.databaseFileName) == null) {
      throw const MaintenanceException(
        'El respaldo no contiene la base local.',
      );
    }

    await _database.close();

    final currentDatabaseFiles = await _databaseFiles();
    for (final file in currentDatabaseFiles) {
      if (await file.exists()) {
        await file.delete();
      }
    }

    for (final entry in archive.files) {
      if (!entry.isFile) {
        continue;
      }

      final fileName = p.basename(entry.name);
      if (_isDatabaseFile(fileName)) {
        final appDir = await getApplicationDocumentsDirectory();
        await File(p.join(appDir.path, fileName)).writeAsBytes(entry.content);
      }
    }

    final backupSettingsFile = archive.findFile(AppFiles.settingsFileName);
    if (backupSettingsFile != null) {
      final currentSettingsFile = await AppFiles.settingsFile();
      await currentSettingsFile.writeAsBytes(backupSettingsFile.content);
    }

    return BackupResult(path: packagePath);
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
        description: 'Cola de sincronización local limpiada',
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
