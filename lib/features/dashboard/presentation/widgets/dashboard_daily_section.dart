import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../data/dashboard_models.dart';
import 'dashboard_comparison_card.dart';
import 'dashboard_formatters.dart';
import 'dashboard_metric_card.dart';
import 'dashboard_product_card.dart';

class DashboardDailySection extends StatelessWidget {
  const DashboardDailySection({super.key, required this.summary});

  final DailyDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desde ${formatDashboardTime(summary.periodStart)}',
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
              icon: Icons.receipt_long_rounded,
              label: 'Ventas realizadas',
              value: summary.salesCount.toString(),
              compact: true,
            ),
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
              icon: Icons.confirmation_number_rounded,
              label: 'Ticket promedio',
              value: formatDashboardMoney(summary.averageTicket),
              compact: true,
            ),
            DashboardMetricCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Caja fisica actual',
              value: formatDashboardMoney(summary.physicalCash),
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardProductCard(
          icon: Icons.attach_money_rounded,
          title: 'Producto con mas ingresos',
          emptyText: 'Sin ventas hoy',
          metric: summary.topRevenueProduct,
          topProducts: summary.topRevenueProducts,
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardProductCard(
          icon: Icons.inventory_2_rounded,
          title: 'Producto mas vendido',
          emptyText: 'Sin ventas hoy',
          metric: summary.topQuantityProduct,
          topProducts: summary.topQuantityProducts,
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardProductCard(
          icon: Icons.sell_rounded,
          title: 'Producto en mas ventas',
          emptyText: 'Sin ventas hoy',
          metric: summary.topSaleCountProduct,
          topProducts: summary.topSaleCountProducts,
          showSaleCount: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Contra ayer', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ingresos',
          comparison: summary.incomeComparison,
          isMoney: true,
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ganancias',
          comparison: summary.profitComparison,
          isMoney: true,
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ventas',
          comparison: summary.salesComparison,
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardComparisonCard(
          title: 'Ticket promedio',
          comparison: summary.ticketComparison,
          isMoney: true,
        ),
      ],
    );
  }
}
