import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/administrative_settings_section.dart';
import '../widgets/personal_settings_sections.dart';
import '../widgets/session_section.dart';
import '../widgets/superadmin_maintenance_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canModifySettings =
        currentUser != null && AppRoles.canModifySettings(currentUser.role);
    final isSuperadmin = currentUser?.role == AppRoles.superadmin;

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
          CurrentUserSection(currentUser: currentUser),
          const SettingsSectionGap(),
          const PreferencesSection(),
          const SettingsSectionGap(),
          const SystemStatusSection(),
          if (canModifySettings) ...[
            const SettingsSectionGap(),
            const AdministrativeSettingsSection(),
          ],
          if (isSuperadmin) ...[
            const SettingsSectionGap(),
            SuperadminMaintenanceSection(currentUser: currentUser!),
          ],
          const SettingsSectionGap(),
          const SessionSection(),
        ],
      ),
    );
  }
}
