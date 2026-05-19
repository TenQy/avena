import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';

class CashButtonContent extends StatelessWidget {
  const CashButtonContent({
    super.key,
    required this.label,
    required this.trailing,
  });

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        const SizedBox(width: AppSpacing.sm),
        trailing,
      ],
    );
  }
}
