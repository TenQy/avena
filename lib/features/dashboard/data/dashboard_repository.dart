import '../../../core/database/app_database.dart';
import 'dashboard_models.dart';
import 'dashboard_summary_calculator.dart';

class DashboardRepository {
  DashboardRepository(this._database, {DashboardSummaryCalculator? calculator})
    : _calculator = calculator ?? const DashboardSummaryCalculator();

  final AppDatabase _database;
  final DashboardSummaryCalculator _calculator;

  Stream<DailyDashboardSummary> watchDailySummary({
    required CashSession? openCashSession,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final periodStart = openCashSession?.openedAt ?? todayStart;
    final periodEnd = openCashSession == null ? tomorrowStart : DateTime(9999);
    final previousStart = todayStart.subtract(const Duration(days: 1));
    final previousEnd = todayStart;

    return _database.salesDao
        .watchSalesBetween(periodStart, periodEnd)
        .asyncMap((sales) async {
          final previousSales = await _database.salesDao
              .watchSalesBetween(previousStart, previousEnd)
              .first;
          final currentCompleted = _calculator.completedSales(sales);
          final previousCompleted = _calculator.completedSales(previousSales);
          final productMetrics = await _calculator.productMetrics(
            _database,
            currentCompleted,
          );
          final totalIncome = _calculator.salesTotal(currentCompleted);
          final previousIncome = _calculator.salesTotal(previousCompleted);
          final totalProfit = await _calculator.profitTotal(
            _database,
            currentCompleted,
          );
          final previousProfit = await _calculator.profitTotal(
            _database,
            previousCompleted,
          );
          final averageTicket = _calculator.averageTicket(currentCompleted);
          final previousAverageTicket = _calculator.averageTicket(
            previousCompleted,
          );

          return DailyDashboardSummary(
            periodStart: periodStart,
            salesCount: currentCompleted.length,
            totalIncome: totalIncome,
            totalProfit: totalProfit,
            averageTicket: averageTicket,
            physicalCash: openCashSession?.expectedCashAmount ?? 0,
            topRevenueProducts: _calculator.topProductsByIncome(productMetrics),
            topQuantityProducts: _calculator.topProductsByQuantity(
              productMetrics,
            ),
            topSaleCountProducts: _calculator.topProductsBySaleCount(
              productMetrics,
            ),
            topRevenueProduct: _calculator.topByIncome(productMetrics),
            topQuantityProduct: _calculator.topByQuantity(productMetrics),
            topSaleCountProduct: _calculator.topBySaleCount(productMetrics),
            incomeComparison: DashboardComparison(
              current: totalIncome,
              previous: previousIncome,
            ),
            profitComparison: DashboardComparison(
              current: totalProfit,
              previous: previousProfit,
            ),
            salesComparison: DashboardComparison(
              current: currentCompleted.length.toDouble(),
              previous: previousCompleted.length.toDouble(),
            ),
            ticketComparison: DashboardComparison(
              current: averageTicket,
              previous: previousAverageTicket,
            ),
          );
        });
  }

  Stream<WeeklyDashboardSummary> watchWeeklySummary() {
    final now = DateTime.now();
    final weekStart = _calculator.startOfWeek(now);
    final nextWeekStart = weekStart.add(const Duration(days: 7));
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));

    return _database.salesDao
        .watchSalesBetween(weekStart, nextWeekStart)
        .asyncMap((sales) async {
          final previousSales = await _database.salesDao
              .watchSalesBetween(previousWeekStart, weekStart)
              .first;
          final currentCompleted = _calculator.completedSales(sales);
          final previousCompleted = _calculator.completedSales(previousSales);
          final productMetrics = await _calculator.productMetrics(
            _database,
            currentCompleted,
          );
          final allProducts = await _database.inventoryDao
              .watchProducts()
              .first;
          final totalIncome = _calculator.salesTotal(currentCompleted);
          final previousIncome = _calculator.salesTotal(previousCompleted);
          final totalProfit = await _calculator.profitTotal(
            _database,
            currentCompleted,
          );
          final previousProfit = await _calculator.profitTotal(
            _database,
            previousCompleted,
          );
          final averageTicket = _calculator.averageTicket(currentCompleted);
          final previousAverageTicket = _calculator.averageTicket(
            previousCompleted,
          );
          final weekPerformance = _calculator.weeklyPerformance(
            currentCompleted,
            weekStart,
          );
          final soldProductIds = await _calculator.soldProductIds(
            _database,
            currentCompleted,
          );
          final paymentDistribution = await _calculator.paymentDistribution(
            _database,
            currentCompleted,
          );

          return WeeklyDashboardSummary(
            periodStart: weekStart,
            periodEnd: nextWeekStart.subtract(const Duration(days: 1)),
            salesCount: currentCompleted.length,
            totalIncome: totalIncome,
            totalProfit: totalProfit,
            averageTicket: averageTicket,
            bestDay: _calculator.bestDay(weekPerformance),
            worstDay: _calculator.worstDay(weekPerformance),
            incomeComparison: DashboardComparison(
              current: totalIncome,
              previous: previousIncome,
            ),
            profitComparison: DashboardComparison(
              current: totalProfit,
              previous: previousProfit,
            ),
            salesComparison: DashboardComparison(
              current: currentCompleted.length.toDouble(),
              previous: previousCompleted.length.toDouble(),
            ),
            ticketComparison: DashboardComparison(
              current: averageTicket,
              previous: previousAverageTicket,
            ),
            topRevenueProducts: _calculator.topProductsByIncome(productMetrics),
            topQuantityProducts: _calculator.topProductsByQuantity(
              productMetrics,
            ),
            topSaleCountProducts: _calculator.topProductsBySaleCount(
              productMetrics,
            ),
            weeklyIncome: weekPerformance,
            paymentDistribution: paymentDistribution,
            productsWithoutSales: _calculator.productsWithoutSales(
              allProducts: allProducts,
              soldProductIds: soldProductIds,
            ),
            topRevenueProduct: _calculator.topByIncome(productMetrics),
            topQuantityProduct: _calculator.topByQuantity(productMetrics),
            topSaleCountProduct: _calculator.topBySaleCount(productMetrics),
          );
        });
  }

  Stream<MonthlyDashboardSummary> watchMonthlySummary() {
    final now = DateTime.now();
    final monthStart = _calculator.startOfMonth(now);
    final nextMonthStart = _calculator.startOfNextMonth(monthStart);
    final previousMonthStart = monthStart.month == 1
        ? DateTime(monthStart.year - 1, 12)
        : DateTime(monthStart.year, monthStart.month - 1);

    return _database.salesDao
        .watchSalesBetween(monthStart, nextMonthStart)
        .asyncMap((sales) async {
          final previousSales = await _database.salesDao
              .watchSalesBetween(previousMonthStart, monthStart)
              .first;
          final currentCompleted = _calculator.completedSales(sales);
          final previousCompleted = _calculator.completedSales(previousSales);
          final productMetrics = await _calculator.productMetrics(
            _database,
            currentCompleted,
          );
          final allProducts = await _database.inventoryDao
              .watchProducts()
              .first;
          final totalIncome = _calculator.salesTotal(currentCompleted);
          final previousIncome = _calculator.salesTotal(previousCompleted);
          final totalProfit = await _calculator.profitTotal(
            _database,
            currentCompleted,
          );
          final previousProfit = await _calculator.profitTotal(
            _database,
            previousCompleted,
          );
          final averageTicket = _calculator.averageTicket(currentCompleted);
          final previousAverageTicket = _calculator.averageTicket(
            previousCompleted,
          );
          final monthlyPerformance = _calculator.monthlyPerformance(
            currentCompleted,
            monthStart,
            nextMonthStart,
          );
          final soldProductIds = await _calculator.soldProductIds(
            _database,
            currentCompleted,
          );

          return MonthlyDashboardSummary(
            periodStart: monthStart,
            periodEnd: nextMonthStart.subtract(const Duration(days: 1)),
            salesCount: currentCompleted.length,
            totalIncome: totalIncome,
            totalProfit: totalProfit,
            averageTicket: averageTicket,
            bestWeek: _calculator.bestPeriod(monthlyPerformance),
            worstWeek: _calculator.worstPeriod(monthlyPerformance),
            incomeComparison: DashboardComparison(
              current: totalIncome,
              previous: previousIncome,
            ),
            profitComparison: DashboardComparison(
              current: totalProfit,
              previous: previousProfit,
            ),
            salesComparison: DashboardComparison(
              current: currentCompleted.length.toDouble(),
              previous: previousCompleted.length.toDouble(),
            ),
            ticketComparison: DashboardComparison(
              current: averageTicket,
              previous: previousAverageTicket,
            ),
            topRevenueProducts: _calculator.topProductsByIncome(productMetrics),
            topQuantityProducts: _calculator.topProductsByQuantity(
              productMetrics,
            ),
            monthlyIncome: monthlyPerformance,
            productsWithoutMovement: _calculator.productsWithoutSales(
              allProducts: allProducts,
              soldProductIds: soldProductIds,
            ),
            topRevenueProduct: _calculator.topByIncome(productMetrics),
            topQuantityProduct: _calculator.topByQuantity(productMetrics),
          );
        });
  }
}
