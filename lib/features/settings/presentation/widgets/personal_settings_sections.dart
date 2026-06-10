import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../providers/settings_provider.dart';
import 'settings_rows.dart';
import 'settings_section_card.dart';

class CurrentUserSection extends StatelessWidget {
  const CurrentUserSection({super.key, required this.currentUser});

  final User? currentUser;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Usuario actual',
      icon: Icons.person_rounded,
      children: [
        SettingsInfoRow(
          label: 'Usuario',
          value: currentUser?.username ?? 'Sesión no disponible',
        ),
        SettingsInfoRow(label: 'Rol', value: _roleLabel(currentUser?.role)),
        SettingsInfoRow(
          label: 'Estado',
          value: currentUser?.isActive == false ? 'Inactivo' : 'Activo',
        ),
        if (currentUser?.phone != null && currentUser!.phone!.trim().isNotEmpty)
          SettingsInfoRow(label: 'Teléfono', value: currentUser!.phone!),
      ],
    );
  }

  String _roleLabel(String? role) {
    return switch (role) {
      AppRoles.superadmin => 'Superadmin',
      AppRoles.admin => 'Admin',
      AppRoles.employee => 'Empleado',
      _ => 'Sin rol',
    };
  }
}

class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(personalSettingsProvider).valueOrNull;

    return SettingsSectionCard(
      title: 'Preferencias',
      icon: Icons.tune_rounded,
      children: [
        SettingsSwitchRow(
          icon: Icons.dark_mode_rounded,
          title: 'Tema oscuro',
          description: 'Cambia la apariencia general de la app.',
          value: themeMode == ThemeMode.dark,
          onChanged: (enabled) {
            ref.read(personalSettingsProvider.notifier).setDarkMode(enabled);
          },
        ),
      ],
    );
  }
}

class SystemStatusSection extends ConsumerWidget {
  const SystemStatusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(basicConnectionProvider);

    return SettingsSectionCard(
      title: 'Sistema',
      icon: Icons.info_rounded,
      children: [
        const SettingsInfoRow(label: 'Version', value: AppConstants.appVersion),
        connection.when(
          data: (status) => SettingsInfoRow(
            label: 'Conexion',
            value: status.hasInternet
                ? 'Internet disponible'
                : 'Sin conexion detectada',
          ),
          loading: () =>
              const SettingsInfoRow(label: 'Conexion', value: 'Revisando...'),
          error: (_, _) => const SettingsInfoRow(
            label: 'Conexion',
            value: 'No se pudo revisar',
          ),
        ),
      ],
    );
  }
}

class SettingsSectionGap extends StatelessWidget {
  const SettingsSectionGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppSpacing.md);
  }
}
