import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../data/dashboard_models.dart';
import 'dashboard_comparison_card.dart';
import 'dashboard_formatters.dart';
import 'dashboard_metric_card.dart';
import 'dashboard_payment_donut_chart.dart';
import 'dashboard_product_card.dart';
import 'dashboard_text_list_card.dart';
import 'dashboard_weekly_income_chart.dart';

class DashboardWeeklySection extends StatelessWidget {
  const DashboardWeeklySection({super.key, required this.summary});

  final WeeklyDashboardSummary summary;

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
              label: 'Mejor dia',
              value: summary.bestDay.label,
              detail:
                  '${formatDashboardMoney(summary.bestDay.income)} - ${summary.bestDay.salesCount} ventas',
              compact: true,
            ),
            DashboardMetricCard(
              icon: Icons.trending_down_rounded,
              label: 'Peor dia',
              value: summary.worstDay.label,
              detail:
                  '${formatDashboardMoney(summary.worstDay.income)} - ${summary.worstDay.salesCount} ventas',
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardWeeklyIncomeChart(items: summary.weeklyIncome),
        const SizedBox(height: AppSpacing.md),
        DashboardPaymentDonutChart(items: summary.paymentDistribution),
        const SizedBox(height: AppSpacing.lg),
        DashboardProductCard(
          icon: Icons.attach_money_rounded,
          title: 'Producto con mas ingresos',
          emptyText: 'Sin ventas esta semana',
          metric: summary.topRevenueProduct,
          topProducts: summary.topRevenueProducts,
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardProductCard(
          icon: Icons.inventory_2_rounded,
          title: 'Producto mas vendido',
          emptyText: 'Sin ventas esta semana',
          metric: summary.topQuantityProduct,
          topProducts: summary.topQuantityProducts,
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardProductCard(
          icon: Icons.sell_rounded,
          title: 'Producto en mas ventas',
          emptyText: 'Sin ventas esta semana',
          metric: summary.topSaleCountProduct,
          topProducts: summary.topSaleCountProducts,
          showSaleCount: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Contra la semana anterior', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ingresos',
          comparison: summary.incomeComparison,
          isMoney: true,
          previousLabel: 'Semana previa',
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ventas',
          comparison: summary.salesComparison,
          previousLabel: 'Semana previa',
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ticket promedio',
          comparison: summary.ticketComparison,
          isMoney: true,
          previousLabel: 'Semana previa',
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardTextListCard(
          icon: Icons.remove_shopping_cart_rounded,
          title: 'Productos sin ventas',
          emptyText: 'Todos tuvieron ventas esta semana',
          items: summary.productsWithoutSales,
        ),
      ],
    );
  }
}
