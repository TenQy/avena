import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/dashboard_repository.dart';

class DashboardComparisonCard extends StatelessWidget {
  const DashboardComparisonCard({
    super.key,
    required this.title,
    required this.comparison,
    this.isMoney = false,
  });

  final String title;
  final DashboardComparison comparison;
  final bool isMoney;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percentChange = comparison.percentChange;
    final isPositive = comparison.difference >= 0;
    final icon = isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.headerNav,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.iconInactive),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    percentChange == null
                        ? 'Sin referencia previa'
                        : '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ayer: ${_formatValue(comparison.previous)}',
                    style: textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (isMoney) {
      return '\$${value.toStringAsFixed(2)}';
    }

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }
}
