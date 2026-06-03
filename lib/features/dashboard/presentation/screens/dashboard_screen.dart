import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/dashboard_models.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/dashboard_daily_section.dart';
import '../widgets/dashboard_monthly_section.dart';
import '../widgets/dashboard_weekly_section.dart';

enum _DashboardView { day, week, month }

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
      _DashboardView.month => ref.watch(monthlyDashboardProvider),
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
  final Object? summary;

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
              : selectedView == _DashboardView.week
              ? 'Resumen de la semana'
              : 'Resumen del mes',
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
            ChoiceChip(
              label: const Text('Mes'),
              selected: selectedView == _DashboardView.month,
              showCheckmark: false,
              onSelected: (_) => onViewSelected(_DashboardView.month),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (summary is DailyDashboardSummary)
          DashboardDailySection(summary: summary as DailyDashboardSummary)
        else if (summary is WeeklyDashboardSummary)
          DashboardWeeklySection(summary: summary as WeeklyDashboardSummary)
        else
          DashboardMonthlySection(summary: summary as MonthlyDashboardSummary),
      ],
    );
  }
}
