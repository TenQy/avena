import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CalculatorProfitMode { percentage, net }

final calculatorProvider =
    StateNotifierProvider<CalculatorController, CalculatorState>((ref) {
      return CalculatorController();
    });

class CalculatorState {
  const CalculatorState({
    this.bulkCost = '',
    this.bulkKilograms = '',
    this.bulkProfit = '',
    this.bulkProfitMode = CalculatorProfitMode.percentage,
    this.customGrams = '',
    this.customGramsPrice = '',
    this.packageCost = '',
    this.packageUnits = '',
    this.unitProfit = '',
    this.unitProfitMode = CalculatorProfitMode.percentage,
  });

  final String bulkCost;
  final String bulkKilograms;
  final String bulkProfit;
  final CalculatorProfitMode bulkProfitMode;
  final String customGrams;
  final String customGramsPrice;
  final String packageCost;
  final String packageUnits;
  final String unitProfit;
  final CalculatorProfitMode unitProfitMode;

  CalculatorState copyWith({
    String? bulkCost,
    String? bulkKilograms,
    String? bulkProfit,
    CalculatorProfitMode? bulkProfitMode,
    String? customGrams,
    String? customGramsPrice,
    String? packageCost,
    String? packageUnits,
    String? unitProfit,
    CalculatorProfitMode? unitProfitMode,
  }) {
    return CalculatorState(
      bulkCost: bulkCost ?? this.bulkCost,
      bulkKilograms: bulkKilograms ?? this.bulkKilograms,
      bulkProfit: bulkProfit ?? this.bulkProfit,
      bulkProfitMode: bulkProfitMode ?? this.bulkProfitMode,
      customGrams: customGrams ?? this.customGrams,
      customGramsPrice: customGramsPrice ?? this.customGramsPrice,
      packageCost: packageCost ?? this.packageCost,
      packageUnits: packageUnits ?? this.packageUnits,
      unitProfit: unitProfit ?? this.unitProfit,
      unitProfitMode: unitProfitMode ?? this.unitProfitMode,
    );
  }
}

class CalculatorController extends StateNotifier<CalculatorState> {
  CalculatorController() : super(const CalculatorState());

  void updateBulkCost(String value) => state = state.copyWith(bulkCost: value);

  void updateBulkKilograms(String value) {
    state = state.copyWith(bulkKilograms: value);
  }

  void updateBulkProfit(String value) {
    state = state.copyWith(bulkProfit: value);
  }

  void selectBulkProfitMode(CalculatorProfitMode mode) {
    state = state.copyWith(bulkProfitMode: mode, bulkProfit: '');
  }

  void updateCustomGrams(String value) {
    state = state.copyWith(customGrams: value);
  }

  void updateCustomGramsPrice(String value) {
    state = state.copyWith(customGramsPrice: value);
  }

  void updatePackageCost(String value) {
    state = state.copyWith(packageCost: value);
  }

  void updatePackageUnits(String value) {
    state = state.copyWith(packageUnits: value);
  }

  void updateUnitProfit(String value) {
    state = state.copyWith(unitProfit: value);
  }

  void selectUnitProfitMode(CalculatorProfitMode mode) {
    state = state.copyWith(unitProfitMode: mode, unitProfit: '');
  }

  void clearBulk() {
    state = state.copyWith(
      bulkCost: '',
      bulkKilograms: '',
      bulkProfit: '',
      customGrams: '',
      customGramsPrice: '',
    );
  }

  void clearUnits() {
    state = state.copyWith(packageCost: '', packageUnits: '', unitProfit: '');
  }
}
