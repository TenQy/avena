import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  await database.customSelect('SELECT 1').get();
  await database.close();

  runApp(const TiendaApp());
}
