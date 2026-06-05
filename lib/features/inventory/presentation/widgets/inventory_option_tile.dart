import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class InventoryOptionTile extends StatelessWidget {
  const InventoryOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bodyBg = AppColors.bodyBgFor(context);
    final border = AppColors.borderFor(context);
    final iconInactive = AppColors.iconInactiveFor(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Icon(icon, color: iconInactive, size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: iconInactive,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}
