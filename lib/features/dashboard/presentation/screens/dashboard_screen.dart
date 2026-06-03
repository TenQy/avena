import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/dashboard_repository.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/dashboard_comparison_card.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/dashboard_product_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dailyDashboardProvider);

    return summaryState.when(
      data: (summary) => _DailyDashboardContent(summary: summary),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Icons.error_outline_rounded,
        message: 'No se pudo cargar el dashboard',
        description: 'Intenta nuevamente.',
      ),
    );
  }
}

class _DailyDashboardContent extends StatelessWidget {
  const _DailyDashboardContent({required this.summary});

  final DailyDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Text('Dashboard diario', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text('Desde ${_time(summary.periodStart)}', style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.25,
          children: [
            DashboardMetricCard(
              icon: Icons.receipt_long_rounded,
              label: 'Ventas realizadas',
              value: summary.salesCount.toString(),
            ),
            DashboardMetricCard(
              icon: Icons.payments_rounded,
              label: 'Ingresos totales',
              value: _money(summary.totalIncome),
            ),
            DashboardMetricCard(
              icon: Icons.confirmation_number_rounded,
              label: 'Ticket promedio',
              value: _money(summary.averageTicket),
            ),
            DashboardMetricCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Caja fisica actual',
              value: _money(summary.physicalCash),
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

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _time(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}
