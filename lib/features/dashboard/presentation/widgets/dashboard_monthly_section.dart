import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../data/dashboard_models.dart';
import 'dashboard_comparison_card.dart';
import 'dashboard_formatters.dart';
import 'dashboard_metric_card.dart';
import 'dashboard_monthly_income_chart.dart';
import 'dashboard_product_card.dart';
import 'dashboard_text_list_card.dart';

class DashboardMonthlySection extends StatelessWidget {
  const DashboardMonthlySection({super.key, required this.summary});

  final MonthlyDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatDashboardShortDate(summary.periodStart)} - ${formatDashboardShortDate(summary.periodEnd)}',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.55,
          children: [
            DashboardMetricCard(
              icon: Icons.payments_rounded,
              label: 'Ingresos totales',
              value: formatDashboardMoney(summary.totalIncome),
              compact: true,
            ),
            DashboardMetricCard(
              icon: Icons.trending_up_rounded,
              label: 'Ganancias',
              value: formatDashboardMoney(summary.totalProfit),
              compact: true,
            ),
            DashboardMetricCard(
              icon: Icons.receipt_long_rounded,
              label: 'Ventas realizadas',
              value: summary.salesCount.toString(),
              compact: true,
            ),
            DashboardMetricCard(
              icon: Icons.confirmation_number_rounded,
              label: 'Ticket promedio',
              value: formatDashboardMoney(summary.averageTicket),
              compact: true,
            ),
            DashboardMetricCard(
              icon: Icons.emoji_events_rounded,
              label: 'Mejor semana',
              value: summary.bestWeek.label,
              detail:
                  '${formatDashboardMoney(summary.bestWeek.income)} - ${summary.bestWeek.salesCount} ventas',
              compact: true,
            ),
            DashboardMetricCard(
              icon: Icons.trending_down_rounded,
              label: 'Peor semana',
              value: summary.worstWeek.label,
              detail:
                  '${formatDashboardMoney(summary.worstWeek.income)} - ${summary.worstWeek.salesCount} ventas',
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardMonthlyIncomeChart(items: summary.monthlyIncome),
        const SizedBox(height: AppSpacing.lg),
        DashboardProductCard(
          icon: Icons.attach_money_rounded,
          title: 'Producto con mas ingresos',
          emptyText: 'Sin ventas este mes',
          metric: summary.topRevenueProduct,
          topProducts: summary.topRevenueProducts,
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardProductCard(
          icon: Icons.inventory_2_rounded,
          title: 'Producto mas vendido',
          emptyText: 'Sin ventas este mes',
          metric: summary.topQuantityProduct,
          topProducts: summary.topQuantityProducts,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Contra el mes anterior', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ingresos',
          comparison: summary.incomeComparison,
          isMoney: true,
          previousLabel: 'Mes previo',
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ganancias',
          comparison: summary.profitComparison,
          isMoney: true,
          previousLabel: 'Mes previo',
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ventas',
          comparison: summary.salesComparison,
          previousLabel: 'Mes previo',
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ticket promedio',
          comparison: summary.ticketComparison,
          isMoney: true,
          previousLabel: 'Mes previo',
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardTextListCard(
          icon: Icons.inventory_rounded,
          title: 'Productos sin movimiento',
          emptyText: 'Todos tuvieron movimiento este mes',
          items: summary.productsWithoutMovement,
        ),
      ],
    );
  }
}
