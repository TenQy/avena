import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/dashboard_models.dart';

class DashboardMonthlyIncomeChart extends StatelessWidget {
  const DashboardMonthlyIncomeChart({super.key, required this.items});

  final List<DashboardPeriodPerformance> items;

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
            Text('Ingresos por semana', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Gráfica de líneas mensual', style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 220,
              child: _MonthlyLineChart(items: items, maxIncome: maxIncome),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyLineChart extends StatelessWidget {
  const _MonthlyLineChart({required this.items, required this.maxIncome});

  final List<DashboardPeriodPerformance> items;
  final double maxIncome;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _MonthlyLineChartPainter(items: items, maxIncome: maxIncome),
        );
      },
    );
  }
}

class _MonthlyLineChartPainter extends CustomPainter {
  _MonthlyLineChartPainter({required this.items, required this.maxIncome});

  final List<DashboardPeriodPerformance> items;
  final double maxIncome;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) {
      return;
    }

    const topPadding = 20.0;
    const bottomPadding = 28.0;
    const sidePadding = 16.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width - (sidePadding * 2);
    final spacing = items.length > 1 ? chartWidth / (items.length - 1) : 0.0;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()..color = AppColors.accent;
    final labelStyle = const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
    );

    for (var index = 0; index < 4; index++) {
      final y = topPadding + (chartHeight / 3) * index;
      canvas.drawLine(
        Offset(sidePadding, y),
        Offset(size.width - sidePadding, y),
        gridPaint,
      );
    }

    final points = <Offset>[];
    for (var index = 0; index < items.length; index++) {
      final ratio = maxIncome == 0 ? 0.0 : items[index].income / maxIncome;
      final x = sidePadding + (spacing * index);
      final y = topPadding + chartHeight - (chartHeight * ratio);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(path, linePaint);

    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], 5, pointPaint);
      final labelPainter = TextPainter(
        text: TextSpan(text: items[index].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(points[index].dx - (labelPainter.width / 2), size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyLineChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.maxIncome != maxIncome;
  }
}
