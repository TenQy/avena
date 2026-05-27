import '../../providers/calculator_provider.dart';

class CustomGramsResult {
  const CustomGramsResult({
    required this.grams,
    required this.cost,
    required this.salePrice,
    required this.netProfit,
    required this.profitPercentage,
    required this.usesCustomPrice,
  });

  final double grams;
  final double cost;
  final double salePrice;
  final double netProfit;
  final double profitPercentage;
  final bool usesCustomPrice;
}

class BulkPriceResult {
  const BulkPriceResult({
    required this.costPerKilogram,
    required this.salePricePerKilogram,
    required this.netProfitPerKilogram,
    required this.profitPercentage,
    required this.salePricePer100Grams,
    required this.salePricePer250Grams,
    required this.salePricePer500Grams,
    this.customGramsResult,
  });

  final double costPerKilogram;
  final double salePricePerKilogram;
  final double netProfitPerKilogram;
  final double profitPercentage;
  final double salePricePer100Grams;
  final double salePricePer250Grams;
  final double salePricePer500Grams;
  final CustomGramsResult? customGramsResult;
}

class UnitPriceResult {
  const UnitPriceResult({
    required this.costPerUnit,
    required this.salePricePerUnit,
    required this.salePricePerPackage,
    required this.netProfitPerUnit,
    required this.profitPercentage,
  });

  final double costPerUnit;
  final double salePricePerUnit;
  final double salePricePerPackage;
  final double netProfitPerUnit;
  final double profitPercentage;
}

class CalculatorMath {
  const CalculatorMath._();

  static BulkPriceResult? calculateBulkPrice({
    required double totalCost,
    required double totalKilograms,
    required double profitValue,
    required CalculatorProfitMode profitMode,
    double? customGrams,
    double? customGramsPrice,
  }) {
    if (totalCost <= 0 || totalKilograms <= 0 || profitValue < 0) {
      return null;
    }

    final costPerKilogram = totalCost / totalKilograms;
    final salePricePerKilogram = _salePrice(
      costPerKilogram,
      profitValue,
      profitMode,
    );
    final netProfitPerKilogram = salePricePerKilogram - costPerKilogram;
    final profitPercentage = _percentage(netProfitPerKilogram, costPerKilogram);
    final validCustomGrams = customGrams != null && customGrams > 0
        ? customGrams
        : null;

    return BulkPriceResult(
      costPerKilogram: _money(costPerKilogram),
      salePricePerKilogram: _money(salePricePerKilogram),
      netProfitPerKilogram: _money(netProfitPerKilogram),
      profitPercentage: _percent(profitPercentage),
      salePricePer100Grams: _gramsPrice(salePricePerKilogram, 100),
      salePricePer250Grams: _gramsPrice(salePricePerKilogram, 250),
      salePricePer500Grams: _gramsPrice(salePricePerKilogram, 500),
      customGramsResult: validCustomGrams == null
          ? null
          : _customGramsResult(
              grams: validCustomGrams,
              costPerKilogram: costPerKilogram,
              calculatedSalePricePerKilogram: salePricePerKilogram,
              customPrice: customGramsPrice,
            ),
    );
  }

  static UnitPriceResult? calculateUnitPrice({
    required double packageCost,
    required double units,
    required double profitValue,
    required CalculatorProfitMode profitMode,
  }) {
    if (packageCost <= 0 || units <= 0 || profitValue < 0) {
      return null;
    }

    final costPerUnit = packageCost / units;
    final salePricePerUnit = _salePrice(costPerUnit, profitValue, profitMode);
    final netProfitPerUnit = salePricePerUnit - costPerUnit;

    return UnitPriceResult(
      costPerUnit: _money(costPerUnit),
      salePricePerUnit: _money(salePricePerUnit),
      salePricePerPackage: _money(salePricePerUnit * units),
      netProfitPerUnit: _money(netProfitPerUnit),
      profitPercentage: _percent(_percentage(netProfitPerUnit, costPerUnit)),
    );
  }

  static CustomGramsResult _customGramsResult({
    required double grams,
    required double costPerKilogram,
    required double calculatedSalePricePerKilogram,
    double? customPrice,
  }) {
    final cost = costPerKilogram * grams / 1000;
    final usesCustomPrice = customPrice != null && customPrice > 0;
    final salePrice = customPrice != null && customPrice > 0
        ? customPrice
        : calculatedSalePricePerKilogram * grams / 1000;
    final netProfit = salePrice - cost;

    return CustomGramsResult(
      grams: grams,
      cost: _money(cost),
      salePrice: _money(salePrice),
      netProfit: _money(netProfit),
      profitPercentage: _percent(_percentage(netProfit, cost)),
      usesCustomPrice: usesCustomPrice,
    );
  }

  static double _salePrice(
    double cost,
    double profitValue,
    CalculatorProfitMode profitMode,
  ) {
    return switch (profitMode) {
      CalculatorProfitMode.percentage => cost * (1 + (profitValue / 100)),
      CalculatorProfitMode.net => cost + profitValue,
    };
  }

  static double _percentage(double profit, double cost) {
    return cost == 0 ? 0 : profit / cost * 100;
  }

  static double _gramsPrice(double kilogramPrice, double grams) {
    return _money(kilogramPrice * grams / 1000);
  }

  static double _money(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  static double _percent(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}
