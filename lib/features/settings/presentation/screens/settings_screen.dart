import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_placeholder.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      icon: Icons.settings_rounded,
      message: 'Configuración',
    );
  }
}
