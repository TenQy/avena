import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class DashboardTextListCard extends StatelessWidget {
  const DashboardTextListCard({
    super.key,
    required this.icon,
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String emptyText;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.headerNavFor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.iconInactiveFor(context)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  if (items.isEmpty)
                    Text(emptyText, style: textTheme.titleMedium)
                  else ...[
                    for (final item in items.take(5)) ...[
                      Text(
                        item,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    if (items.length > 5)
                      Text(
                        '+${items.length - 5} mas',
                        style: textTheme.labelSmall,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
