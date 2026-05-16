import 'package:flutter/material.dart';

import 'features/home/presentation/screens/home_screen.dart';
import 'shared/theme/app_theme.dart';

class TiendaApp extends StatelessWidget {
  const TiendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tienda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
