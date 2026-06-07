import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../../cash/providers/cash_provider.dart';
import '../../data/settings_local_source.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final themeMode = ref.watch(personalSettingsProvider).valueOrNull;
    final connection = ref.watch(basicConnectionProvider);
    final canModifySettings =
        currentUser != null && AppRoles.canModifySettings(currentUser.role);

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
          if (canModifySettings) ...[
            const SizedBox(height: AppSpacing.md),
            const _AdministrativeSettingsSection(),
          ],
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Sesion',
            icon: Icons.logout_rounded,
            children: [
              FilledButton.icon(
                onPressed: () => _logout(context, ref),
                icon: Icon(Icons.logout_rounded),
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
    final palette = _SettingsPalette.of(context);

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
                    color: palette.iconBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: palette.border, width: 0.5),
                  ),
                  child: Icon(icon, color: palette.icon, size: 22),
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

class _AdministrativeSettingsSection extends ConsumerWidget {
  const _AdministrativeSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(administrativeSettingsProvider);
    final cashState = ref.watch(currentCashSessionProvider);
    final syncState = ref.watch(localSyncStatusProvider);

    return Column(
      children: [
        _SectionCard(
          title: 'Negocio',
          icon: Icons.store_rounded,
          children: [
            settingsState.when(
              data: (settings) => Column(
                children: [
                  _InfoRow(
                    label: 'Nombre',
                    value: settings.businessName.isEmpty
                        ? 'Sin configurar'
                        : settings.businessName,
                  ),
                  _InfoRow(
                    label: 'Telefono',
                    value: settings.businessPhone.isEmpty
                        ? 'Sin configurar'
                        : settings.businessPhone,
                  ),
                  _InfoRow(
                    label: 'Direccion',
                    value: settings.businessAddress.isEmpty
                        ? 'Sin configurar'
                        : settings.businessAddress,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Editar informacion',
                    onPressed: () => _BusinessInfoSheet.show(
                      context,
                      settings,
                    ),
                  ),
                ],
              ),
              loading: () => const _InfoRow(label: 'Estado', value: 'Cargando...'),
              error: (_, _) => const _InfoRow(
                label: 'Estado',
                value: 'No se pudo cargar',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Comisiones',
          icon: Icons.percent_rounded,
          children: [
            settingsState.when(
              data: (settings) => Column(
                children: [
                  _InfoRow(
                    label: 'Tarjeta',
                    value: _percent(settings.commissionRates.terminalCard),
                  ),
                  _InfoRow(
                    label: 'Bonos',
                    value: _percent(settings.commissionRates.terminalBonus),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsActionButton(
                    icon: Icons.tune_rounded,
                    label: 'Editar comisiones',
                    onPressed: () => _CommissionRatesSheet.show(
                      context,
                      settings,
                    ),
                  ),
                ],
              ),
              loading: () => const _InfoRow(label: 'Estado', value: 'Cargando...'),
              error: (_, _) => const _InfoRow(
                label: 'Estado',
                value: 'No se pudo cargar',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Caja actual',
          icon: Icons.point_of_sale_rounded,
          children: [
            cashState.when(
              data: (session) {
                if (session == null) {
                  return const _InfoRow(label: 'Estado', value: 'Sin caja abierta');
                }

                return Column(
                  children: [
                    _InfoRow(label: 'Estado', value: 'Abierta'),
                    _InfoRow(
                      label: 'Caja fisica',
                      value: _money(session.expectedCashAmount),
                    ),
                    _InfoRow(
                      label: 'Ingresos digitales',
                      value: _money(
                        session.transferIncome +
                            session.terminalIncome +
                            session.bonusIncome,
                      ),
                    ),
                    _InfoRow(
                      label: 'Comisiones',
                      value: _money(session.commissionTotal),
                    ),
                  ],
                );
              },
              loading: () => const _InfoRow(label: 'Estado', value: 'Cargando...'),
              error: (_, _) => const _InfoRow(
                label: 'Estado',
                value: 'No se pudo cargar',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Sincronizacion local',
          icon: Icons.sync_rounded,
          children: [
            syncState.when(
              data: (status) => Column(
                children: [
                  _InfoRow(
                    label: 'Operaciones pendientes',
                    value: status.pendingCount.toString(),
                  ),
                  _InfoRow(
                    label: 'Con error local',
                    value: status.failedCount.toString(),
                  ),
                ],
              ),
              loading: () => const _InfoRow(label: 'Estado', value: 'Cargando...'),
              error: (_, _) => const _InfoRow(
                label: 'Estado',
                value: 'No se pudo cargar',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _BusinessInfoSheet extends ConsumerStatefulWidget {
  const _BusinessInfoSheet({required this.initialSettings});

  final AdministrativeSettings initialSettings;

  static Future<void> show(
    BuildContext context,
    AdministrativeSettings settings,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BusinessInfoSheet(initialSettings: settings),
    );
  }

  @override
  ConsumerState<_BusinessInfoSheet> createState() => _BusinessInfoSheetState();
}

class _BusinessInfoSheetState extends ConsumerState<_BusinessInfoSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialSettings.businessName;
    _phoneController.text = widget.initialSettings.businessPhone;
    _addressController.text = widget.initialSettings.businessAddress;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: AppSpacing.lg),
            Text('Informacion del negocio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre del negocio',
                prefixIcon: Icon(Icons.store_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Telefono',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _addressController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Direccion',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.save_rounded),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    await ref
        .read(administrativeSettingsProvider.notifier)
        .saveBusinessInfo(
          businessName: _nameController.text,
          businessPhone: _phoneController.text,
          businessAddress: _addressController.text,
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }
}

class _CommissionRatesSheet extends ConsumerStatefulWidget {
  const _CommissionRatesSheet({required this.initialSettings});

  final AdministrativeSettings initialSettings;

  static Future<void> show(
    BuildContext context,
    AdministrativeSettings settings,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommissionRatesSheet(initialSettings: settings),
    );
  }

  @override
  ConsumerState<_CommissionRatesSheet> createState() =>
      _CommissionRatesSheetState();
}

class _CommissionRatesSheetState extends ConsumerState<_CommissionRatesSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController();
  final _bonusController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cardController.text = _formatPercent(
      widget.initialSettings.commissionRates.terminalCard,
    );
    _bonusController.text = _formatPercent(
      widget.initialSettings.commissionRates.terminalBonus,
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _bonusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const SizedBox(height: AppSpacing.lg),
              Text('Comisiones', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              _PercentField(
                controller: _cardController,
                label: 'Tarjeta',
              ),
              const SizedBox(height: AppSpacing.md),
              _PercentField(
                controller: _bonusController,
                label: 'Bonos',
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.save_rounded),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref
        .read(administrativeSettingsProvider.notifier)
        .saveCommissionRates(
          cardPercent: double.parse(_cardController.text.trim()),
          bonusPercent: double.parse(_bonusController.text.trim()),
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }
}

class _PercentField extends StatelessWidget {
  const _PercentField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: '$label (%)',
        prefixIcon: const Icon(Icons.percent_rounded),
      ),
      validator: (value) {
        final percent = double.tryParse(value?.trim() ?? '');
        if (percent == null || percent < 0 || percent > 100) {
          return 'Ingresa un porcentaje entre 0 y 100.';
        }

        return null;
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderFor(context),
          borderRadius: BorderRadius.circular(2),
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
    final palette = _SettingsPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.secondaryText,
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

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _percent(double rate) {
  final value = rate * 100;
  return value == value.roundToDouble()
      ? '${value.toStringAsFixed(0)}%'
      : '${value.toStringAsFixed(1)}%';
}

String _formatPercent(double rate) {
  final value = rate * 100;
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
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
    final palette = _SettingsPalette.of(context);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: palette.secondaryText),
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

class _SettingsPalette {
  const _SettingsPalette({
    required this.iconBackground,
    required this.icon,
    required this.border,
    required this.secondaryText,
  });

  final Color iconBackground;
  final Color icon;
  final Color border;
  final Color secondaryText;

  static _SettingsPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return _SettingsPalette(
        iconBackground: Color(0xFF3A2F26),
        icon: Color(0xFFE8D2B0),
        border: Color(0xFF5B4635),
        secondaryText: Color(0xFFD4BFA0),
      );
    }

    return _SettingsPalette(
      iconBackground: AppColors.headerNavFor(context),
      icon: AppColors.textPrimaryFor(context),
      border: AppColors.borderFor(context),
      secondaryText: AppColors.textSecondaryFor(context),
    );
  }
}
