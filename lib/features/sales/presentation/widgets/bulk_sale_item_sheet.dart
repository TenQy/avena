import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../models/sale_draft_item.dart';

class BulkSaleItemDraft {
  const BulkSaleItemDraft({required this.quantity, required this.subtotal});

  final double quantity;
  final double subtotal;
}

class BulkSaleItemSheet extends StatefulWidget {
  const BulkSaleItemSheet({super.key, required this.item});

  final SaleDraftItem item;

  @override
  State<BulkSaleItemSheet> createState() => _BulkSaleItemSheetState();
}

class _BulkSaleItemSheetState extends State<BulkSaleItemSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _weightController;
  bool _updatingFields = false;
  bool _useGrams = false;

  double get _pricePerKilogram => widget.item.product.price;
  double get _availableStock => widget.item.product.stockQuantity ?? 0;
  bool get _tracksStock => widget.item.product.trackStock;
  bool get _exceedsStock {
    final weight = _readWeightInKilograms();
    return _tracksStock && weight != null && weight > _availableStock;
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _formatDecimal(widget.item.subtotal, decimals: 2),
    );
    _weightController = TextEditingController(
      text: _formatDecimal(widget.item.quantity, decimals: 3),
    );
    _amountController.addListener(_onAmountChanged);
    _weightController.addListener(_onWeightChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _weightController.removeListener(_onWeightChanged);
    _amountController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderFor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.item.product.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _tracksStock
                  ? '${_money(_pricePerKilogram)} por kg Ã‚Â· Stock: ${_formatDecimal(_availableStock)} kg'
                  : '${_money(_pricePerKilogram)} por kg',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryFor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Costo',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: false, label: Text('kg')),
                ButtonSegment<bool>(value: true, label: Text('gr')),
              ],
              selected: {_useGrams},
              onSelectionChanged: (selection) {
                _changeWeightUnit(selection.first);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(_weightInputPattern),
              ],
              decoration: InputDecoration(
                labelText: _useGrams ? 'Peso en gr' : 'Peso en kg',
                prefixIcon: const Icon(Icons.scale_rounded),
                errorText: _exceedsStock ? 'Supera el stock disponible' : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _exceedsStock ? null : _save,
              child: const _ButtonContent(
                label: 'Actualizar',
                icon: Icons.check_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAmountChanged() {
    if (_updatingFields) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || _pricePerKilogram <= 0) {
      return;
    }

    final weightInKilograms = amount / _pricePerKilogram;
    _setWeightText(weightInKilograms);
    setState(() {});
  }

  void _onWeightChanged() {
    if (_updatingFields) {
      return;
    }

    final weightInKilograms = _readWeightInKilograms();
    if (weightInKilograms == null) {
      return;
    }

    _setText(
      _amountController,
      _formatDecimal(weightInKilograms * _pricePerKilogram, decimals: 2),
    );
    setState(() {});
  }

  RegExp get _weightInputPattern {
    return _useGrams ? RegExp(r'^\d*$') : RegExp(r'^\d*\.?\d{0,3}');
  }

  void _changeWeightUnit(bool useGrams) {
    if (_useGrams == useGrams) {
      return;
    }

    final weightInKilograms = _readWeightInKilograms();

    setState(() {
      _useGrams = useGrams;
    });

    if (weightInKilograms != null) {
      _setWeightText(weightInKilograms);
    }
  }

  double? _readWeightInKilograms() {
    final rawWeight = double.tryParse(_weightController.text.trim());
    if (rawWeight == null) {
      return null;
    }

    return _useGrams ? rawWeight / 1000 : rawWeight;
  }

  void _setWeightText(double weightInKilograms) {
    final text = _useGrams
        ? (weightInKilograms * 1000).round().toString()
        : _formatDecimal(weightInKilograms);

    _setText(_weightController, text);
  }

  void _setText(TextEditingController controller, String text) {
    _updatingFields = true;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _updatingFields = false;
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    final weight = _readWeightInKilograms();

    if (amount == null ||
        amount <= 0 ||
        weight == null ||
        weight <= 0 ||
        (_tracksStock && weight > _availableStock)) {
      return;
    }

    Navigator.of(
      context,
    ).pop(BulkSaleItemDraft(quantity: weight, subtotal: amount));
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        const SizedBox(width: AppSpacing.sm),
        Icon(icon),
      ],
    );
  }
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

String _formatDecimal(double value, {int decimals = 3}) {
  final text = value.toStringAsFixed(decimals);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
