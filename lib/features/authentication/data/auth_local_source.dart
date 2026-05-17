import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AuthLocalSource {
  const AuthLocalSource();

  static const _sessionFileName = 'auth_session.json';
  static const _userIdKey = 'userId';

  Future<String?> readCurrentUserId() async {
    final file = await _sessionFile();

    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data is Map<String, Object?>) {
        return data[_userIdKey] as String?;
      }
    } on FormatException {
      await clearCurrentUserId();
    }

    return null;
  }

  Future<void> saveCurrentUserId(String userId) async {
    final file = await _sessionFile();
    await file.writeAsString(jsonEncode({_userIdKey: userId}));
  }

  Future<void> clearCurrentUserId() async {
    final file = await _sessionFile();

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _sessionFile() async {
    final appDir = await getApplicationDocumentsDirectory();

    return File(p.join(appDir.path, _sessionFileName));
  }
}
