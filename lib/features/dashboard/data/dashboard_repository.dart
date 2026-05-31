import '../../../core/constants/app_sales.dart';
import '../../../core/constants/app_products.dart';
import '../../../core/database/app_database.dart';

class DailyDashboardSummary {
  const DailyDashboardSummary({
    required this.periodStart,
    required this.salesCount,
    required this.totalIncome,
    required this.averageTicket,
    required this.physicalCash,
    required this.incomeComparison,
    required this.salesComparison,
    required this.ticketComparison,
    this.topRevenueProduct,
    this.topQuantityProduct,
    this.topSaleCountProduct,
  });

  final DateTime periodStart;
  final int salesCount;
  final double totalIncome;
  final double averageTicket;
  final double physicalCash;
  final DashboardComparison incomeComparison;
  final DashboardComparison salesComparison;
  final DashboardComparison ticketComparison;
  final DashboardProductMetric? topRevenueProduct;
  final DashboardProductMetric? topQuantityProduct;
  final DashboardProductMetric? topSaleCountProduct;
}

class DashboardComparison {
  const DashboardComparison({required this.current, required this.previous});

  final double current;
  final double previous;

  double get difference => current - previous;

  bool get hasPrevious => previous > 0;

  double? get percentChange {
    if (!hasPrevious) {
      return null;
    }

    return (difference / previous) * 100;
  }
}

class DashboardProductMetric {
  const DashboardProductMetric({
    required this.name,
    required this.productType,
    required this.quantity,
    required this.income,
    required this.saleCount,
  });

  final String name;
  final String productType;
  final double quantity;
  final double income;
  final int saleCount;

  bool get isBulk => productType == AppProductTypes.bulk;
}

class DashboardRepository {
  DashboardRepository(this._database);

  final AppDatabase _database;

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

          final currentCompleted = _completedSales(sales);
          final previousCompleted = _completedSales(previousSales);
          final productMetrics = await _productMetrics(currentCompleted);
          final totalIncome = _salesTotal(currentCompleted);
          final previousIncome = _salesTotal(previousCompleted);
          final averageTicket = _averageTicket(currentCompleted);
          final previousAverageTicket = _averageTicket(previousCompleted);

          return DailyDashboardSummary(
            periodStart: periodStart,
            salesCount: currentCompleted.length,
            totalIncome: totalIncome,
            averageTicket: averageTicket,
            physicalCash: openCashSession?.expectedCashAmount ?? 0,
            topRevenueProduct: _topByIncome(productMetrics),
            topQuantityProduct: _topByQuantity(productMetrics),
            topSaleCountProduct: _topBySaleCount(productMetrics),
            incomeComparison: DashboardComparison(
              current: totalIncome,
              previous: previousIncome,
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

  List<Sale> _completedSales(List<Sale> sales) {
    return sales
        .where((sale) => sale.saleStatus != AppSaleStatuses.cancelled)
        .toList();
  }

  double _salesTotal(List<Sale> sales) {
    return _roundMoney(sales.fold(0, (total, sale) => total + sale.total));
  }

  double _averageTicket(List<Sale> sales) {
    if (sales.isEmpty) {
      return 0;
    }

    return _roundMoney(_salesTotal(sales) / sales.length);
  }

  Future<List<DashboardProductMetric>> _productMetrics(List<Sale> sales) async {
    final products = <String, _ProductAccumulator>{};

    for (final sale in sales) {
      final items = await _database.salesDao.getItemsBySale(sale.id);

      for (final item in items) {
        final current = products.putIfAbsent(
          item.productId,
          () => _ProductAccumulator(
            name: item.productNameSnapshot,
            productType: item.productTypeSnapshot,
          ),
        );

        current.quantity += item.quantity;
        current.income += item.subtotal;
        current.saleIds.add(sale.id);
      }
    }

    return products.values
        .map(
          (product) => DashboardProductMetric(
            name: product.name,
            productType: product.productType,
            quantity: _roundQuantity(product.quantity),
            income: _roundMoney(product.income),
            saleCount: product.saleIds.length,
          ),
        )
        .toList();
  }

  DashboardProductMetric? _topByIncome(List<DashboardProductMetric> metrics) {
    if (metrics.isEmpty) {
      return null;
    }

    return metrics.reduce(
      (current, next) => next.income > current.income ? next : current,
    );
  }

  DashboardProductMetric? _topByQuantity(List<DashboardProductMetric> metrics) {
    if (metrics.isEmpty) {
      return null;
    }

    return metrics.reduce(
      (current, next) => next.quantity > current.quantity ? next : current,
    );
  }

  DashboardProductMetric? _topBySaleCount(
    List<DashboardProductMetric> metrics,
  ) {
    if (metrics.isEmpty) {
      return null;
    }

    return metrics.reduce(
      (current, next) => next.saleCount > current.saleCount ? next : current,
    );
  }

  double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));

  double _roundQuantity(double value) => double.parse(value.toStringAsFixed(3));
}

class _ProductAccumulator {
  _ProductAccumulator({required this.name, required this.productType});

  final String name;
  final String productType;
  double quantity = 0;
  double income = 0;
  final Set<String> saleIds = {};
}
