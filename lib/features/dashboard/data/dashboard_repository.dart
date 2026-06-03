import '../../../core/constants/payment_methods.dart';
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
    required this.topRevenueProducts,
    required this.topQuantityProducts,
    required this.topSaleCountProducts,
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
  final List<DashboardProductMetric> topRevenueProducts;
  final List<DashboardProductMetric> topQuantityProducts;
  final List<DashboardProductMetric> topSaleCountProducts;
  final DashboardProductMetric? topRevenueProduct;
  final DashboardProductMetric? topQuantityProduct;
  final DashboardProductMetric? topSaleCountProduct;
}

class WeeklyDashboardSummary {
  const WeeklyDashboardSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.salesCount,
    required this.totalIncome,
    required this.averageTicket,
    required this.bestDay,
    required this.worstDay,
    required this.incomeComparison,
    required this.salesComparison,
    required this.ticketComparison,
    required this.topRevenueProducts,
    required this.topQuantityProducts,
    required this.topSaleCountProducts,
    required this.weeklyIncome,
    required this.paymentDistribution,
    required this.productsWithoutSales,
    this.topRevenueProduct,
    this.topQuantityProduct,
    this.topSaleCountProduct,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final int salesCount;
  final double totalIncome;
  final double averageTicket;
  final DashboardDayPerformance bestDay;
  final DashboardDayPerformance worstDay;
  final DashboardComparison incomeComparison;
  final DashboardComparison salesComparison;
  final DashboardComparison ticketComparison;
  final List<DashboardProductMetric> topRevenueProducts;
  final List<DashboardProductMetric> topQuantityProducts;
  final List<DashboardProductMetric> topSaleCountProducts;
  final List<DashboardDayPerformance> weeklyIncome;
  final List<DashboardPaymentMetric> paymentDistribution;
  final List<String> productsWithoutSales;
  final DashboardProductMetric? topRevenueProduct;
  final DashboardProductMetric? topQuantityProduct;
  final DashboardProductMetric? topSaleCountProduct;
}

class DashboardDayPerformance {
  const DashboardDayPerformance({
    required this.date,
    required this.label,
    required this.income,
    required this.salesCount,
  });

  final DateTime date;
  final String label;
  final double income;
  final int salesCount;
}

class DashboardPaymentMetric {
  const DashboardPaymentMetric({
    required this.method,
    required this.label,
    required this.amount,
  });

  final String method;
  final String label;
  final double amount;
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
            topRevenueProducts: _topProductsByIncome(productMetrics),
            topQuantityProducts: _topProductsByQuantity(productMetrics),
            topSaleCountProducts: _topProductsBySaleCount(productMetrics),
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

  Stream<WeeklyDashboardSummary> watchWeeklySummary() {
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final nextWeekStart = weekStart.add(const Duration(days: 7));
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));

    return _database.salesDao
        .watchSalesBetween(weekStart, nextWeekStart)
        .asyncMap((sales) async {
          final previousSales = await _database.salesDao
              .watchSalesBetween(previousWeekStart, weekStart)
              .first;
          final currentCompleted = _completedSales(sales);
          final previousCompleted = _completedSales(previousSales);
          final productMetrics = await _productMetrics(currentCompleted);
          final allProducts = await _database.inventoryDao
              .watchProducts()
              .first;
          final totalIncome = _salesTotal(currentCompleted);
          final previousIncome = _salesTotal(previousCompleted);
          final averageTicket = _averageTicket(currentCompleted);
          final previousAverageTicket = _averageTicket(previousCompleted);
          final weekPerformance = _weeklyPerformance(
            currentCompleted,
            weekStart,
          );
          final soldProductIds = await _soldProductIds(currentCompleted);
          final paymentDistribution = await _paymentDistribution(
            currentCompleted,
          );

          return WeeklyDashboardSummary(
            periodStart: weekStart,
            periodEnd: nextWeekStart.subtract(const Duration(days: 1)),
            salesCount: currentCompleted.length,
            totalIncome: totalIncome,
            averageTicket: averageTicket,
            bestDay: _bestDay(weekPerformance),
            worstDay: _worstDay(weekPerformance),
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
            topRevenueProducts: _topProductsByIncome(productMetrics),
            topQuantityProducts: _topProductsByQuantity(productMetrics),
            topSaleCountProducts: _topProductsBySaleCount(productMetrics),
            weeklyIncome: weekPerformance,
            paymentDistribution: paymentDistribution,
            productsWithoutSales: _productsWithoutSales(
              allProducts: allProducts,
              soldProductIds: soldProductIds,
            ),
            topRevenueProduct: _topByIncome(productMetrics),
            topQuantityProduct: _topByQuantity(productMetrics),
            topSaleCountProduct: _topBySaleCount(productMetrics),
          );
        });
  }

  List<Sale> _completedSales(List<Sale> sales) {
    return sales
        .where((sale) => sale.saleStatus != AppSaleStatuses.cancelled)
        .toList();
  }

  DateTime _startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
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

  Future<Set<String>> _soldProductIds(List<Sale> sales) async {
    final soldProductIds = <String>{};

    for (final sale in sales) {
      final items = await _database.salesDao.getItemsBySale(sale.id);
      for (final item in items) {
        soldProductIds.add(item.productId);
      }
    }

    return soldProductIds;
  }

  Future<List<DashboardPaymentMetric>> _paymentDistribution(
    List<Sale> sales,
  ) async {
    final totals = <String, double>{};

    for (final sale in sales) {
      final payments = await _database.salesDao.getPaymentsBySale(sale.id);
      for (final payment in payments) {
        totals.update(
          payment.paymentMethod,
          (current) => current + payment.totalCharged,
          ifAbsent: () => payment.totalCharged,
        );
      }
    }

    return totals.entries
        .map(
          (entry) => DashboardPaymentMetric(
            method: entry.key,
            label: _paymentMethodLabel(entry.key),
            amount: _roundMoney(entry.value),
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  DashboardProductMetric? _topByIncome(List<DashboardProductMetric> metrics) {
    final topProducts = _topProductsByIncome(metrics);
    if (topProducts.isEmpty) {
      return null;
    }

    return topProducts.first;
  }

  DashboardProductMetric? _topByQuantity(List<DashboardProductMetric> metrics) {
    final topProducts = _topProductsByQuantity(metrics);
    if (topProducts.isEmpty) {
      return null;
    }

    return topProducts.first;
  }

  DashboardProductMetric? _topBySaleCount(
    List<DashboardProductMetric> metrics,
  ) {
    final topProducts = _topProductsBySaleCount(metrics);
    if (topProducts.isEmpty) {
      return null;
    }

    return topProducts.first;
  }

  List<DashboardProductMetric> _topProductsByIncome(
    List<DashboardProductMetric> metrics,
  ) {
    final sorted = [...metrics]
      ..sort((a, b) {
        final incomeComparison = b.income.compareTo(a.income);
        if (incomeComparison != 0) {
          return incomeComparison;
        }

        return b.quantity.compareTo(a.quantity);
      });

    return sorted.take(5).toList(growable: false);
  }

  List<DashboardProductMetric> _topProductsByQuantity(
    List<DashboardProductMetric> metrics,
  ) {
    final sorted = [...metrics]
      ..sort((a, b) {
        final quantityComparison = b.quantity.compareTo(a.quantity);
        if (quantityComparison != 0) {
          return quantityComparison;
        }

        return b.income.compareTo(a.income);
      });

    return sorted.take(5).toList(growable: false);
  }

  List<DashboardProductMetric> _topProductsBySaleCount(
    List<DashboardProductMetric> metrics,
  ) {
    final sorted = [...metrics]
      ..sort((a, b) {
        final saleCountComparison = b.saleCount.compareTo(a.saleCount);
        if (saleCountComparison != 0) {
          return saleCountComparison;
        }

        return b.quantity.compareTo(a.quantity);
      });

    return sorted.take(5).toList(growable: false);
  }

  List<DashboardDayPerformance> _weeklyPerformance(
    List<Sale> sales,
    DateTime weekStart,
  ) {
    final salesByDay = <DateTime, List<Sale>>{};

    for (var index = 0; index < 7; index++) {
      final day = weekStart.add(Duration(days: index));
      salesByDay[day] = [];
    }

    for (final sale in sales) {
      final day = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      salesByDay.putIfAbsent(day, () => []).add(sale);
    }

    return salesByDay.entries
        .map((entry) {
          final daySales = entry.value;

          return DashboardDayPerformance(
            date: entry.key,
            label: _weekdayLabel(entry.key.weekday),
            income: _salesTotal(daySales),
            salesCount: daySales.length,
          );
        })
        .toList(growable: false);
  }

  DashboardDayPerformance _bestDay(List<DashboardDayPerformance> performance) {
    return performance.reduce((current, next) {
      final incomeComparison = next.income.compareTo(current.income);
      if (incomeComparison != 0) {
        return incomeComparison > 0 ? next : current;
      }

      return next.salesCount > current.salesCount ? next : current;
    });
  }

  DashboardDayPerformance _worstDay(List<DashboardDayPerformance> performance) {
    return performance.reduce((current, next) {
      final incomeComparison = next.income.compareTo(current.income);
      if (incomeComparison != 0) {
        return incomeComparison < 0 ? next : current;
      }

      return next.salesCount < current.salesCount ? next : current;
    });
  }

  List<String> _productsWithoutSales({
    required List<Product> allProducts,
    required Set<String> soldProductIds,
  }) {
    return allProducts
        .where(
          (product) => product.isActive && !soldProductIds.contains(product.id),
        )
        .map((product) => product.name)
        .toList(growable: false);
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Lunes';
      case DateTime.tuesday:
        return 'Martes';
      case DateTime.wednesday:
        return 'Miercoles';
      case DateTime.thursday:
        return 'Jueves';
      case DateTime.friday:
        return 'Viernes';
      case DateTime.saturday:
        return 'Sabado';
      case DateTime.sunday:
        return 'Domingo';
    }

    return '';
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case AppPaymentMethods.cash:
        return 'Efectivo';
      case AppPaymentMethods.transfer:
        return 'Transferencia';
      case AppPaymentMethods.terminalCard:
        return 'Debito/Credito';
      case AppPaymentMethods.terminalBonus:
        return 'Bonos';
      case AppPaymentMethods.mixed:
        return 'Mixto';
    }

    return method;
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
