import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_dismiss_area.dart';
import '../../providers/calculator_provider.dart';
import '../utils/calculator_math.dart';
import '../widgets/calculator_cards.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  late final TextEditingController _bulkCostController;
  late final TextEditingController _bulkKilogramsController;
  late final TextEditingController _bulkProfitController;
  late final TextEditingController _customGramsController;
  late final TextEditingController _customGramsPriceController;
  late final TextEditingController _packageCostController;
  late final TextEditingController _packageUnitsController;
  late final TextEditingController _unitProfitController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(calculatorProvider);
    _bulkCostController = TextEditingController(text: state.bulkCost);
    _bulkKilogramsController = TextEditingController(text: state.bulkKilograms);
    _bulkProfitController = TextEditingController(text: state.bulkProfit);
    _customGramsController = TextEditingController(text: state.customGrams);
    _customGramsPriceController = TextEditingController(
      text: state.customGramsPrice,
    );
    _packageCostController = TextEditingController(text: state.packageCost);
    _packageUnitsController = TextEditingController(text: state.packageUnits);
    _unitProfitController = TextEditingController(text: state.unitProfit);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
    _bulkCostController,
    _bulkKilogramsController,
    _bulkProfitController,
    _customGramsController,
    _customGramsPriceController,
    _packageCostController,
    _packageUnitsController,
    _unitProfitController,
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorProvider);
    final controller = ref.read(calculatorProvider.notifier);
    final bulkResult = CalculatorMath.calculateBulkPrice(
      totalCost: _number(state.bulkCost),
      totalKilograms: _number(state.bulkKilograms),
      profitValue: _number(state.bulkProfit),
      profitMode: state.bulkProfitMode,
      customGrams: _optionalNumber(state.customGrams),
      customGramsPrice: _optionalNumber(state.customGramsPrice),
    );
    final unitResult = CalculatorMath.calculateUnitPrice(
      packageCost: _number(state.packageCost),
      units: _number(state.packageUnits),
      profitValue: _number(state.unitProfit),
      profitMode: state.unitProfitMode,
    );

    return AppDismissArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          BulkCalculatorCard(
            costController: _bulkCostController,
            kilogramsController: _bulkKilogramsController,
            profitController: _bulkProfitController,
            customGramsController: _customGramsController,
            customGramsPriceController: _customGramsPriceController,
            profitMode: state.bulkProfitMode,
            result: bulkResult,
            onCostChanged: controller.updateBulkCost,
            onKilogramsChanged: controller.updateBulkKilograms,
            onProfitChanged: controller.updateBulkProfit,
            onProfitModeChanged: (mode) {
              _bulkProfitController.clear();
              controller.selectBulkProfitMode(mode);
            },
            onCustomGramsChanged: controller.updateCustomGrams,
            onCustomGramsPriceChanged: controller.updateCustomGramsPrice,
            onClear: () {
              _clear([
                _bulkCostController,
                _bulkKilogramsController,
                _bulkProfitController,
                _customGramsController,
                _customGramsPriceController,
              ]);
              controller.clearBulk();
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          UnitCalculatorCard(
            packageCostController: _packageCostController,
            packageUnitsController: _packageUnitsController,
            profitController: _unitProfitController,
            profitMode: state.unitProfitMode,
            result: unitResult,
            onPackageCostChanged: controller.updatePackageCost,
            onPackageUnitsChanged: controller.updatePackageUnits,
            onProfitChanged: controller.updateUnitProfit,
            onProfitModeChanged: (mode) {
              _unitProfitController.clear();
              controller.selectUnitProfitMode(mode);
            },
            onClear: () {
              _clear([
                _packageCostController,
                _packageUnitsController,
                _unitProfitController,
              ]);
              controller.clearUnits();
            },
          ),
        ],
      ),
    );
  }

  void _clear(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.clear();
    }
  }
}

double _number(String value) => double.tryParse(value.trim()) ?? 0;

double? _optionalNumber(String value) {
  final parsedValue = double.tryParse(value.trim());
  return parsedValue == null || parsedValue <= 0 ? null : parsedValue;
}
