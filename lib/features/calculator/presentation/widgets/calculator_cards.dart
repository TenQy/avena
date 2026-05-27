import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../providers/calculator_provider.dart';
import '../utils/calculator_math.dart';
import 'calculator_result_card.dart';

class BulkCalculatorCard extends StatelessWidget {
  const BulkCalculatorCard({
    super.key,
    required this.costController,
    required this.kilogramsController,
    required this.profitController,
    required this.customGramsController,
    required this.customGramsPriceController,
    required this.profitMode,
    required this.result,
    required this.onCostChanged,
    required this.onKilogramsChanged,
    required this.onProfitChanged,
    required this.onProfitModeChanged,
    required this.onCustomGramsChanged,
    required this.onCustomGramsPriceChanged,
    required this.onClear,
  });

  final TextEditingController costController;
  final TextEditingController kilogramsController;
  final TextEditingController profitController;
  final TextEditingController customGramsController;
  final TextEditingController customGramsPriceController;
  final CalculatorProfitMode profitMode;
  final BulkPriceResult? result;
  final ValueChanged<String> onCostChanged;
  final ValueChanged<String> onKilogramsChanged;
  final ValueChanged<String> onProfitChanged;
  final ValueChanged<CalculatorProfitMode> onProfitModeChanged;
  final ValueChanged<String> onCustomGramsChanged;
  final ValueChanged<String> onCustomGramsPriceChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              icon: Icons.scale_rounded,
              title: 'Por peso',
              onClear: onClear,
            ),
            const SizedBox(height: AppSpacing.lg),
            _MoneyField(
              controller: costController,
              label: 'Costo total',
              onChanged: onCostChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _NumberField(
              controller: kilogramsController,
              label: 'Kilogramos',
              icon: Icons.scale_outlined,
              onChanged: onKilogramsChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfitInput(
              controller: profitController,
              mode: profitMode,
              netLabel: 'Ganancia neta por kg',
              onModeChanged: onProfitModeChanged,
              onChanged: onProfitChanged,
            ),
            if (result != null) ...[
              const SizedBox(height: AppSpacing.lg),
              CalculatorResultCard(
                title: 'Precio por peso',
                rows: [
                  CalculatorResultRow(
                    label: 'Costo por kg',
                    value: _money(result!.costPerKilogram),
                  ),
                  CalculatorResultRow(
                    label: 'Ganancia neta por kg',
                    value: _money(result!.netProfitPerKilogram),
                  ),
                  CalculatorResultRow(
                    label: 'Ganancia',
                    value: _percent(result!.profitPercentage),
                  ),
                  CalculatorResultRow(
                    label: 'Precio por kg',
                    value: _money(result!.salePricePerKilogram),
                    emphasized: true,
                  ),
                  CalculatorResultRow(
                    label: '100 g / 250 g / 500 g',
                    value:
                        '${_money(result!.salePricePer100Grams)} / '
                        '${_money(result!.salePricePer250Grams)} / '
                        '${_money(result!.salePricePer500Grams)}',
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SubsectionLabel(label: 'Cotizar gramos'),
            const SizedBox(height: AppSpacing.md),
            _NumberField(
              controller: customGramsController,
              label: 'Gramos',
              icon: Icons.straighten_rounded,
              onChanged: onCustomGramsChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _MoneyField(
              controller: customGramsPriceController,
              label: 'Precio personalizado (opcional)',
              onChanged: onCustomGramsPriceChanged,
            ),
            if (result?.customGramsResult != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _CustomGramsResultCard(result: result!.customGramsResult!),
            ],
          ],
        ),
      ),
    );
  }
}

class UnitCalculatorCard extends StatelessWidget {
  const UnitCalculatorCard({
    super.key,
    required this.packageCostController,
    required this.packageUnitsController,
    required this.profitController,
    required this.profitMode,
    required this.result,
    required this.onPackageCostChanged,
    required this.onPackageUnitsChanged,
    required this.onProfitChanged,
    required this.onProfitModeChanged,
    required this.onClear,
  });

  final TextEditingController packageCostController;
  final TextEditingController packageUnitsController;
  final TextEditingController profitController;
  final CalculatorProfitMode profitMode;
  final UnitPriceResult? result;
  final ValueChanged<String> onPackageCostChanged;
  final ValueChanged<String> onPackageUnitsChanged;
  final ValueChanged<String> onProfitChanged;
  final ValueChanged<CalculatorProfitMode> onProfitModeChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Por unidad',
              onClear: onClear,
            ),
            const SizedBox(height: AppSpacing.lg),
            _MoneyField(
              controller: packageCostController,
              label: 'Costo de caja o paquete',
              onChanged: onPackageCostChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _NumberField(
              controller: packageUnitsController,
              label: 'Unidades',
              icon: Icons.numbers_rounded,
              onChanged: onPackageUnitsChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfitInput(
              controller: profitController,
              mode: profitMode,
              netLabel: 'Ganancia neta por unidad',
              onModeChanged: onProfitModeChanged,
              onChanged: onProfitChanged,
            ),
            if (result != null) ...[
              const SizedBox(height: AppSpacing.lg),
              CalculatorResultCard(
                title: 'Precio por unidad',
                rows: [
                  CalculatorResultRow(
                    label: 'Costo unitario',
                    value: _money(result!.costPerUnit),
                  ),
                  CalculatorResultRow(
                    label: 'Ganancia neta unitaria',
                    value: _money(result!.netProfitPerUnit),
                  ),
                  CalculatorResultRow(
                    label: 'Ganancia',
                    value: _percent(result!.profitPercentage),
                  ),
                  CalculatorResultRow(
                    label: 'Precio unitario',
                    value: _money(result!.salePricePerUnit),
                    emphasized: true,
                  ),
                  CalculatorResultRow(
                    label: 'Precio caja o paquete',
                    value: _money(result!.salePricePerPackage),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomGramsResultCard extends StatelessWidget {
  const _CustomGramsResultCard({required this.result});

  final CustomGramsResult result;

  @override
  Widget build(BuildContext context) {
    return CalculatorResultCard(
      title: result.usesCustomPrice
          ? 'Precio personalizado'
          : '${_quantity(result.grams)} g',
      rows: [
        CalculatorResultRow(label: 'Costo', value: _money(result.cost)),
        CalculatorResultRow(
          label: 'Ganancia neta',
          value: _money(result.netProfit),
        ),
        CalculatorResultRow(
          label: 'Ganancia',
          value: _percent(result.profitPercentage),
        ),
        CalculatorResultRow(
          label: 'Precio',
          value: _money(result.salePrice),
          emphasized: true,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onClear,
  });

  final IconData icon;
  final String title;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.iconInactive),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton(onPressed: onClear, child: const Text('Limpiar')),
      ],
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProfitInput extends StatelessWidget {
  const _ProfitInput({
    required this.controller,
    required this.mode,
    required this.netLabel,
    required this.onModeChanged,
    required this.onChanged,
  });

  final TextEditingController controller;
  final CalculatorProfitMode mode;
  final String netLabel;
  final ValueChanged<CalculatorProfitMode> onModeChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<CalculatorProfitMode>(
          segments: const [
            ButtonSegment(
              value: CalculatorProfitMode.percentage,
              label: Text('Porcentaje'),
            ),
            ButtonSegment(
              value: CalculatorProfitMode.net,
              label: Text('Ganancia neta'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) => onModeChanged(selection.first),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalFormatter],
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: mode == CalculatorProfitMode.percentage
                ? 'Ganancia (%)'
                : netLabel,
            prefixIcon: Icon(
              mode == CalculatorProfitMode.percentage
                  ? Icons.percent_rounded
                  : Icons.attach_money_rounded,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_decimalFormatter],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.attach_money_rounded),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_decimalFormatter],
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

final _decimalFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'^\d*\.?\d{0,2}'),
);

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _percent(double value) => '${value.toStringAsFixed(2)}%';

String _quantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}
