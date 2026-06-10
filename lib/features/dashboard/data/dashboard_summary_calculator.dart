import '../../../core/constants/payment_methods.dart';
import '../../../core/constants/app_sales.dart';
import '../../../core/database/app_database.dart';
import 'dashboard_models.dart';

class DashboardSummaryCalculator {
  const DashboardSummaryCalculator();

  DateTime startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  DateTime startOfMonth(DateTime value) {
    return DateTime(value.year, value.month);
  }

  DateTime startOfNextMonth(DateTime value) {
    return value.month == 12
        ? DateTime(value.year + 1, 1)
        : DateTime(value.year, value.month + 1);
  }

  List<Sale> completedSales(List<Sale> sales) {
    return sales
        .where((sale) => sale.saleStatus != AppSaleStatuses.cancelled)
        .toList(growable: false);
  }

  double salesTotal(List<Sale> sales) {
    return _roundMoney(sales.fold(0, (total, sale) => total + sale.total));
  }

  Future<double> profitTotal(AppDatabase database, List<Sale> sales) async {
    var total = 0.0;

    for (final sale in sales) {
      final items = await database.salesDao.getItemsBySale(sale.id);
      for (final item in items) {
        final costSubtotal = item.costSubtotalSnapshot;
        if (costSubtotal == null) {
          continue;
        }

        total += item.subtotal - costSubtotal;
      }
    }

    return _roundMoney(total);
  }

  double averageTicket(List<Sale> sales) {
    if (sales.isEmpty) {
      return 0;
    }

    return _roundMoney(salesTotal(sales) / sales.length);
  }

  Future<List<DashboardProductMetric>> productMetrics(
    AppDatabase database,
    List<Sale> sales,
  ) async {
    final products = <String, _ProductAccumulator>{};

    for (final sale in sales) {
      final items = await database.salesDao.getItemsBySale(sale.id);

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
        .toList(growable: false);
  }

  Future<Set<String>> soldProductIds(
    AppDatabase database,
    List<Sale> sales,
  ) async {
    final soldProductIds = <String>{};

    for (final sale in sales) {
      final items = await database.salesDao.getItemsBySale(sale.id);
      for (final item in items) {
        soldProductIds.add(item.productId);
      }
    }

    return soldProductIds;
  }

  Future<List<DashboardPaymentMetric>> paymentDistribution(
    AppDatabase database,
    List<Sale> sales,
  ) async {
    final totals = <String, double>{};

    for (final sale in sales) {
      final payments = await database.salesDao.getPaymentsBySale(sale.id);
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
            label: paymentMethodLabel(entry.key),
            amount: _roundMoney(entry.value),
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  DashboardProductMetric? topByIncome(List<DashboardProductMetric> metrics) {
    final topProducts = topProductsByIncome(metrics);
    return topProducts.isEmpty ? null : topProducts.first;
  }

  DashboardProductMetric? topByQuantity(List<DashboardProductMetric> metrics) {
    final topProducts = topProductsByQuantity(metrics);
    return topProducts.isEmpty ? null : topProducts.first;
  }

  DashboardProductMetric? topBySaleCount(List<DashboardProductMetric> metrics) {
    final topProducts = topProductsBySaleCount(metrics);
    return topProducts.isEmpty ? null : topProducts.first;
  }

  List<DashboardProductMetric> topProductsByIncome(
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

  List<DashboardProductMetric> topProductsByQuantity(
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

  List<DashboardProductMetric> topProductsBySaleCount(
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

  List<DashboardDayPerformance> weeklyPerformance(
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
            label: weekdayLabel(entry.key.weekday),
            income: salesTotal(daySales),
            salesCount: daySales.length,
          );
        })
        .toList(growable: false);
  }

  List<DashboardPeriodPerformance> monthlyPerformance(
    List<Sale> sales,
    DateTime monthStart,
    DateTime nextMonthStart,
  ) {
    final ranges = <_MonthRange>[
      _MonthRange(
        label: 'Semana 1',
        start: monthStart,
        end: monthStart.add(const Duration(days: 7)),
      ),
      _MonthRange(
        label: 'Semana 2',
        start: monthStart.add(const Duration(days: 7)),
        end: monthStart.add(const Duration(days: 14)),
      ),
      _MonthRange(
        label: 'Semana 3',
        start: monthStart.add(const Duration(days: 14)),
        end: monthStart.add(const Duration(days: 21)),
      ),
      _MonthRange(
        label: 'Semana 4',
        start: monthStart.add(const Duration(days: 21)),
        end: nextMonthStart,
      ),
    ];

    return ranges
        .map((range) {
          final rangeSales = sales
              .where((sale) {
                return !sale.createdAt.isBefore(range.start) &&
                    sale.createdAt.isBefore(range.end);
              })
              .toList(growable: false);

          return DashboardPeriodPerformance(
            label: range.label,
            income: salesTotal(rangeSales),
            salesCount: rangeSales.length,
          );
        })
        .toList(growable: false);
  }

  DashboardDayPerformance bestDay(List<DashboardDayPerformance> performance) {
    return performance.reduce((current, next) {
      final incomeComparison = next.income.compareTo(current.income);
      if (incomeComparison != 0) {
        return incomeComparison > 0 ? next : current;
      }

      return next.salesCount > current.salesCount ? next : current;
    });
  }

  DashboardDayPerformance worstDay(List<DashboardDayPerformance> performance) {
    return performance.reduce((current, next) {
      final incomeComparison = next.income.compareTo(current.income);
      if (incomeComparison != 0) {
        return incomeComparison < 0 ? next : current;
      }

      return next.salesCount < current.salesCount ? next : current;
    });
  }

  DashboardPeriodPerformance bestPeriod(
    List<DashboardPeriodPerformance> performance,
  ) {
    return performance.reduce((current, next) {
      final incomeComparison = next.income.compareTo(current.income);
      if (incomeComparison != 0) {
        return incomeComparison > 0 ? next : current;
      }

      return next.salesCount > current.salesCount ? next : current;
    });
  }

  DashboardPeriodPerformance worstPeriod(
    List<DashboardPeriodPerformance> performance,
  ) {
    return performance.reduce((current, next) {
      final incomeComparison = next.income.compareTo(current.income);
      if (incomeComparison != 0) {
        return incomeComparison < 0 ? next : current;
      }

      return next.salesCount < current.salesCount ? next : current;
    });
  }

  List<String> productsWithoutSales({
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

  String weekdayLabel(int weekday) {
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

  String paymentMethodLabel(String method) {
    switch (method) {
      case AppPaymentMethods.cash:
        return 'Efectivo';
      case AppPaymentMethods.transfer:
        return 'Transferencia';
      case AppPaymentMethods.terminalCard:
        return 'Débito/Crédito';
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

class _MonthRange {
  const _MonthRange({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final DateTime start;
  final DateTime end;
}
