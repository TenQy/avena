import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingsLocalSource {
  const SettingsLocalSource();

  static const _settingsFileName = 'personal_settings.json';
  static const _themeModeKey = 'themeMode';

  Future<ThemeMode> readThemeMode() async {
    final file = await _settingsFile();

    if (!await file.exists()) {
      return ThemeMode.light;
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data is Map<String, Object?>) {
        return _themeModeFromName(data[_themeModeKey] as String?);
      }
    } on FormatException {
      await clear();
    }

    return ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode({_themeModeKey: themeMode.name}));
  }

  Future<void> clear() async {
    final file = await _settingsFile();

    if (await file.exists()) {
      await file.delete();
    }
  }

  ThemeMode _themeModeFromName(String? name) {
    return switch (name) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  Future<File> _settingsFile() async {
    final appDir = await getApplicationDocumentsDirectory();

    return File(p.join(appDir.path, _settingsFileName));
  }
}
