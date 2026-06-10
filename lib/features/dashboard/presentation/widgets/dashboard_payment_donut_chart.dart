import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/dashboard_models.dart';

class DashboardPaymentDonutChart extends StatelessWidget {
  const DashboardPaymentDonutChart({super.key, required this.items});

  final List<DashboardPaymentMetric> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Métodos de pago', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Gráfica de dona semanal', style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              Text('Sin ventas esta semana', style: textTheme.bodyMedium)
            else ...[
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      items: items,
                      colors: _chartColors,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total', style: textTheme.bodySmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var index = 0; index < items.length; index++) ...[
                _LegendRow(
                  color: _chartColors[index % _chartColors.length],
                  label: items[index].label,
                  amount: items[index].amount,
                  total: total,
                ),
                if (index < items.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.total,
  });

  final Color color;
  final String label;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percent = total == 0 ? 0.0 : (amount / total) * 100;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        Text(
          '${percent.toStringAsFixed(0)}%  \$${amount.toStringAsFixed(2)}',
          style: textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.items, required this.colors});

  final List<DashboardPaymentMetric> items;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    if (total <= 0) {
      return;
    }

    final strokeWidth = 24.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var startAngle = -math.pi / 2;

    for (var index = 0; index < items.length; index++) {
      final sweepAngle = (items[index].amount / total) * (math.pi * 2);
      paint.color = colors[index % colors.length];
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}

const _chartColors = <Color>[
  AppColors.accent,
  AppColors.iconInactive,
  AppColors.textPrimary,
  AppColors.border,
  AppColors.headerNav,
];
