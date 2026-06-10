import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../cash/providers/cash_provider.dart';
import '../../providers/settings_provider.dart';
import '../sheets/business_info_sheet.dart';
import '../sheets/commission_rates_sheet.dart';
import 'settings_formatters.dart';
import 'settings_rows.dart';
import 'settings_section_card.dart';

class AdministrativeSettingsSection extends ConsumerWidget {
  const AdministrativeSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(administrativeSettingsProvider);
    final cashState = ref.watch(currentCashSessionProvider);
    final syncState = ref.watch(localSyncStatusProvider);

    return Column(
      children: [
        SettingsSectionCard(
          title: 'Negocio',
          icon: Icons.store_rounded,
          children: [
            settingsState.when(
              data: (settings) => Column(
                children: [
                  SettingsInfoRow(
                    label: 'Nombre',
                    value: settings.businessName.isEmpty
                        ? 'Sin configurar'
                        : settings.businessName,
                  ),
                  SettingsInfoRow(
                    label: 'Teléfono',
                    value: settings.businessPhone.isEmpty
                        ? 'Sin configurar'
                        : settings.businessPhone,
                  ),
                  SettingsInfoRow(
                    label: 'Direccion',
                    value: settings.businessAddress.isEmpty
                        ? 'Sin configurar'
                        : settings.businessAddress,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Editar informacion',
                    onPressed: () => BusinessInfoSheet.show(context, settings),
                  ),
                ],
              ),
              loading: () =>
                  const SettingsInfoRow(label: 'Estado', value: 'Cargando...'),
              error: (_, _) => const SettingsInfoRow(
                label: 'Estado',
                value: 'No se pudo cargar',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsSectionCard(
          title: 'Comisiones',
          icon: Icons.percent_rounded,
          children: [
            settingsState.when(
              data: (settings) => Column(
                children: [
                  SettingsInfoRow(
                    label: 'Tarjeta',
                    value: settingsPercent(
                      settings.commissionRates.terminalCard,
                    ),
                  ),
                  SettingsInfoRow(
                    label: 'Bonos',
                    value: settingsPercent(
                      settings.commissionRates.terminalBonus,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SettingsActionButton(
                    icon: Icons.tune_rounded,
                    label: 'Editar comisiones',
                    onPressed: () =>
                        CommissionRatesSheet.show(context, settings),
                  ),
                ],
              ),
              loading: () =>
                  const SettingsInfoRow(label: 'Estado', value: 'Cargando...'),
              error: (_, _) => const SettingsInfoRow(
                label: 'Estado',
                value: 'No se pudo cargar',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsSectionCard(
          title: 'Caja actual',
          icon: Icons.point_of_sale_rounded,
          children: [
            cashState.when(
              data: (session) {
                if (session == null) {
                  return const SettingsInfoRow(
                    label: 'Estado',
                    value: 'Sin caja abierta',
                  );
                }

                return Column(
                  children: [
                    const SettingsInfoRow(label: 'Estado', value: 'Abierta'),
                    SettingsInfoRow(
                      label: 'Caja fisica',
                      value: settingsMoney(session.expectedCashAmount),
                    ),
                    SettingsInfoRow(
                      label: 'Ingresos digitales',
                      value: settingsMoney(
                        session.transferIncome +
                            session.terminalIncome +
                            session.bonusIncome,
                      ),
                    ),
                    SettingsInfoRow(
                      label: 'Comisiones',
                      value: settingsMoney(session.commissionTotal),
                    ),
                  ],
                );
              },
              loading: () =>
                  const SettingsInfoRow(label: 'Estado', value: 'Cargando...'),
              error: (_, _) => const SettingsInfoRow(
                label: 'Estado',
                value: 'No se pudo cargar',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsSectionCard(
          title: 'Sincronización local',
          icon: Icons.sync_rounded,
          children: [
            syncState.when(
              data: (status) => Column(
                children: [
                  SettingsInfoRow(
                    label: 'Operaciones pendientes',
                    value: status.pendingCount.toString(),
                  ),
                  SettingsInfoRow(
                    label: 'Con error local',
                    value: status.failedCount.toString(),
                  ),
                ],
              ),
              loading: () =>
                  const SettingsInfoRow(label: 'Estado', value: 'Cargando...'),
              error: (_, _) => const SettingsInfoRow(
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
