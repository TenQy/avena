import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppFiles {
  const AppFiles._();

  static const databaseFileName = 'tienda.sqlite';
  static const settingsFileName = 'personal_settings.json';
  static const backupDirectoryName = 'tienda_backups';

  static Future<File> databaseFile() async {
    final appDir = await getApplicationDocumentsDirectory();

    return File(p.join(appDir.path, databaseFileName));
  }

  static Future<File> settingsFile() async {
    final appDir = await getApplicationDocumentsDirectory();

    return File(p.join(appDir.path, settingsFileName));
  }

  static Future<Directory> backupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();

    return Directory(p.join(appDir.path, backupDirectoryName));
  }
}
