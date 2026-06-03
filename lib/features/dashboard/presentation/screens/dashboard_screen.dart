import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/dashboard_repository.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/dashboard_comparison_card.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/dashboard_payment_donut_chart.dart';
import '../widgets/dashboard_product_card.dart';
import '../widgets/dashboard_text_list_card.dart';
import '../widgets/dashboard_weekly_income_chart.dart';

enum _DashboardView { day, week }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _DashboardView _selectedView = _DashboardView.day;

  @override
  Widget build(BuildContext context) {
    final summaryState = switch (_selectedView) {
      _DashboardView.day => ref.watch(dailyDashboardProvider),
      _DashboardView.week => ref.watch(weeklyDashboardProvider),
    };

    return summaryState.when(
      data: (summary) => _DashboardContent(
        selectedView: _selectedView,
        onViewSelected: (view) {
          setState(() {
            _selectedView = view;
          });
        },
        summary: summary,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Icons.error_outline_rounded,
        message: 'No se pudo cargar el dashboard',
        description: 'Intenta nuevamente.',
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.selectedView,
    required this.onViewSelected,
    required this.summary,
  });

  final _DashboardView selectedView;
  final ValueChanged<_DashboardView> onViewSelected;
  final Object summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          selectedView == _DashboardView.day
              ? 'Resumen del dia'
              : 'Resumen de la semana',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Dia'),
              selected: selectedView == _DashboardView.day,
              showCheckmark: false,
              onSelected: (_) => onViewSelected(_DashboardView.day),
            ),
            ChoiceChip(
              label: const Text('Semana'),
              selected: selectedView == _DashboardView.week,
              showCheckmark: false,
              onSelected: (_) => onViewSelected(_DashboardView.week),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (summary is DailyDashboardSummary)
          _DailyDashboardContent(summary: summary as DailyDashboardSummary)
        else
          _WeeklyDashboardContent(summary: summary as WeeklyDashboardSummary),
      ],
    );
  }
}

class _DailyDashboardContent extends StatelessWidget {
  const _DailyDashboardContent({required this.summary});

  final DailyDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

class _WeeklyDashboardContent extends StatelessWidget {
  const _WeeklyDashboardContent({required this.summary});

  final WeeklyDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_shortDate(summary.periodStart)} - ${_shortDate(summary.periodEnd)}',
          style: textTheme.bodySmall,
        ),
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
              icon: Icons.payments_rounded,
              label: 'Ingresos totales',
              value: _money(summary.totalIncome),
            ),
            DashboardMetricCard(
              icon: Icons.receipt_long_rounded,
              label: 'Ventas realizadas',
              value: summary.salesCount.toString(),
            ),
            DashboardMetricCard(
              icon: Icons.confirmation_number_rounded,
              label: 'Ticket promedio',
              value: _money(summary.averageTicket),
            ),
            DashboardMetricCard(
              icon: Icons.emoji_events_rounded,
              label: 'Mejor dia',
              value: summary.bestDay.label,
              detail:
                  '${_money(summary.bestDay.income)} - ${summary.bestDay.salesCount} ventas',
            ),
            DashboardMetricCard(
              icon: Icons.trending_down_rounded,
              label: 'Peor dia',
              value: summary.worstDay.label,
              detail:
                  '${_money(summary.worstDay.income)} - ${summary.worstDay.salesCount} ventas',
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

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _time(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String _shortDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month';
}
