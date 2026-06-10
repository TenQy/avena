import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/authentication/providers/auth_provider.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'features/navigation/presentation/screens/main_shell.dart';
import 'features/settings/providers/settings_provider.dart';
import 'shared/theme/app_theme.dart';

class TiendaApp extends ConsumerWidget {
  const TiendaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode =
        ref.watch(personalSettingsProvider).valueOrNull ?? ThemeMode.light;

    return MaterialApp(
      title: 'Tienda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: authState.when(
        data: (state) {
          if (state.isAuthenticated) {
            return const MainShell();
          }

          return const LoginScreen();
        },
        loading: () => const _AuthLoadingScreen(),
        error: (_, _) => const LoginScreen(),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
