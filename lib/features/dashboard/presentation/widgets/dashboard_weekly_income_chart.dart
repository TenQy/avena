import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/dashboard_repository.dart';

class DashboardWeeklyIncomeChart extends StatelessWidget {
  const DashboardWeeklyIncomeChart({super.key, required this.items});

  final List<DashboardDayPerformance> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxIncome = items.fold<double>(
      0,
      (current, item) => item.income > current ? item.income : current,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingresos por dia', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Grafica de barras semanal', style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final item in items)
                    Expanded(
                      child: _IncomeBar(
                        label: _shortLabel(item.label),
                        value: item.income,
                        maxValue: maxIncome,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortLabel(String label) {
    if (label.length <= 3) {
      return label;
    }

    return label.substring(0, 3);
  }
}

class _IncomeBar extends StatelessWidget {
  const _IncomeBar({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final double value;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    final barHeight = 120 * ratio;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value == 0 ? '\$0' : '\$${value.toStringAsFixed(0)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 120,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: AppColors.headerNav,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              height: barHeight < 8 && value > 0 ? 8 : barHeight,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
