import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final themeMode = ref.watch(personalSettingsProvider).valueOrNull;
    final connection = ref.watch(basicConnectionProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(basicConnectionProvider);
        await ref.read(basicConnectionProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          100,
        ),
        children: [
          _SectionCard(
            title: 'Usuario actual',
            icon: Icons.person_rounded,
            children: [
              _InfoRow(
                label: 'Usuario',
                value: currentUser?.username ?? 'Sesion no disponible',
              ),
              _InfoRow(label: 'Rol', value: _roleLabel(currentUser?.role)),
              _InfoRow(
                label: 'Estado',
                value: currentUser?.isActive == false ? 'Inactivo' : 'Activo',
              ),
              if (currentUser?.phone != null &&
                  currentUser!.phone!.trim().isNotEmpty)
                _InfoRow(label: 'Telefono', value: currentUser.phone!),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Preferencias',
            icon: Icons.tune_rounded,
            children: [
              _SettingsSwitchRow(
                icon: Icons.dark_mode_rounded,
                title: 'Tema oscuro',
                description: 'Cambia la apariencia general de la app.',
                value: themeMode == ThemeMode.dark,
                onChanged: (enabled) {
                  ref
                      .read(personalSettingsProvider.notifier)
                      .setDarkMode(enabled);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Sistema',
            icon: Icons.info_rounded,
            children: [
              _InfoRow(label: 'Version', value: AppConstants.appVersion),
              connection.when(
                data: (status) => _InfoRow(
                  label: 'Conexion',
                  value: status.hasInternet
                      ? 'Internet disponible'
                      : 'Sin conexion detectada',
                ),
                loading: () => const _InfoRow(
                  label: 'Conexion',
                  value: 'Revisando...',
                ),
                error: (_, _) => const _InfoRow(
                  label: 'Conexion',
                  value: 'No se pudo revisar',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Sesion',
            icon: Icons.logout_rounded,
            children: [
              FilledButton.icon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesion'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _roleLabel(String? role) {
    return switch (role) {
      AppRoles.superadmin => 'Superadmin',
      AppRoles.admin => 'Admin',
      AppRoles.employee => 'Empleado',
      _ => 'Sin rol',
    };
  }

  static Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await ConfirmDialog.show(
      context,
      title: 'Cerrar sesion',
      message: 'Quieres cerrar tu sesion actual?',
      confirmLabel: 'Cerrar sesion',
      icon: Icons.logout_rounded,
    );

    if (!context.mounted || !shouldLogout) {
      return;
    }

    await ref.read(authProvider.notifier).logout();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.headerNav,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Icon(icon, color: AppColors.textPrimary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: AppColors.iconInactive),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        description,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
