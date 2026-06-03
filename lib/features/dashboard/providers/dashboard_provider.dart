import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../cash/providers/cash_provider.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(databaseProvider));
});

final dailyDashboardProvider = StreamProvider<DailyDashboardSummary>((ref) {
  final cashSession = ref.watch(currentCashSessionProvider).valueOrNull;

  return ref
      .watch(dashboardRepositoryProvider)
      .watchDailySummary(openCashSession: cashSession);
});

final weeklyDashboardProvider = StreamProvider<WeeklyDashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchWeeklySummary();
});
