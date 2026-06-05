import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class CashIconHeader extends StatelessWidget {
  const CashIconHeader({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.headerNavFor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderFor(context), width: 0.5),
          ),
          child: Icon(icon, color: AppColors.textPrimaryFor(context)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}
