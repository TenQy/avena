import '../../../core/constants/app_products.dart';

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

class MonthlyDashboardSummary {
  const MonthlyDashboardSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.salesCount,
    required this.totalIncome,
    required this.averageTicket,
    required this.bestWeek,
    required this.worstWeek,
    required this.incomeComparison,
    required this.salesComparison,
    required this.ticketComparison,
    required this.topRevenueProducts,
    required this.topQuantityProducts,
    required this.monthlyIncome,
    required this.productsWithoutMovement,
    this.topRevenueProduct,
    this.topQuantityProduct,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final int salesCount;
  final double totalIncome;
  final double averageTicket;
  final DashboardPeriodPerformance bestWeek;
  final DashboardPeriodPerformance worstWeek;
  final DashboardComparison incomeComparison;
  final DashboardComparison salesComparison;
  final DashboardComparison ticketComparison;
  final List<DashboardProductMetric> topRevenueProducts;
  final List<DashboardProductMetric> topQuantityProducts;
  final List<DashboardPeriodPerformance> monthlyIncome;
  final List<String> productsWithoutMovement;
  final DashboardProductMetric? topRevenueProduct;
  final DashboardProductMetric? topQuantityProduct;
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

class DashboardPeriodPerformance {
  const DashboardPeriodPerformance({
    required this.label,
    required this.income,
    required this.salesCount,
  });

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
