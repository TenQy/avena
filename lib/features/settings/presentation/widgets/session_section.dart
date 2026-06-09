import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../authentication/providers/auth_provider.dart';
import 'settings_section_card.dart';

class SessionSection extends ConsumerWidget {
  const SessionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSectionCard(
      title: 'Sesion',
      icon: Icons.logout_rounded,
      children: [
        FilledButton.icon(
          onPressed: () => _logout(context, ref),
          icon: Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesion'),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
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
