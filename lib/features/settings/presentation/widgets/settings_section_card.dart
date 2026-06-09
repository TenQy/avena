import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = SettingsPalette.of(context);

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

class SettingsPalette {
  const SettingsPalette({
    required this.iconBackground,
    required this.icon,
    required this.border,
    required this.secondaryText,
  });

  final Color iconBackground;
  final Color icon;
  final Color border;
  final Color secondaryText;

  static SettingsPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const SettingsPalette(
        iconBackground: Color(0xFF3A2F26),
        icon: Color(0xFFE8D2B0),
        border: Color(0xFF5B4635),
        secondaryText: Color(0xFFD4BFA0),
      );
    }

    return SettingsPalette(
      iconBackground: AppColors.headerNavFor(context),
      icon: AppColors.textPrimaryFor(context),
      border: AppColors.borderFor(context),
      secondaryText: AppColors.textSecondaryFor(context),
    );
  }
}
