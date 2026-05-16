import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'empty_state.dart';

class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: EmptyState(
        icon: icon,
        message: message,
        description: 'Modulo pendiente para una fase posterior.',
      ),
    );
  }
}
