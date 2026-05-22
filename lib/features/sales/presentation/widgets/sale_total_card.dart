import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class SaleTotalCard extends StatefulWidget {
  const SaleTotalCard({
    super.key,
    required this.subtotal,
    required this.commission,
    required this.showCashPayment,
  });

  final double subtotal;
  final double commission;
  final bool showCashPayment;

  double get total => subtotal + commission;

  @override
  State<SaleTotalCard> createState() => _SaleTotalCardState();
}

class _SaleTotalCardState extends State<SaleTotalCard> {
  final _paidWithController = TextEditingController();
  double _paidWith = 0;

  double get _change =>
      (_paidWith - widget.total).clamp(0.0, double.infinity).toDouble();

  @override
  void initState() {
    super.initState();
    _paidWithController.addListener(_onPaidWithChanged);
  }

  @override
  void dispose() {
    _paidWithController.removeListener(_onPaidWithChanged);
    _paidWithController.dispose();
    super.dispose();
  }

  void _onPaidWithChanged() {
    setState(() {
      _paidWith = double.tryParse(_paidWithController.text.trim()) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TotalRow(label: 'Subtotal', value: _money(widget.subtotal)),
            const SizedBox(height: AppSpacing.md),
            _TotalRow(label: 'Comision', value: _money(widget.commission)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.border,
              ),
            ),
            _TotalRow(
              label: 'Total',
              value: _money(widget.total),
              emphasized: true,
            ),
            if (widget.showCashPayment) ...[
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _paidWithController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Recibido en efectivo',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TotalRow(label: 'Cambio', value: _money(_change)),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: null,
              child: const _ButtonContent(
                label: 'Registrar venta',
                icon: Icons.point_of_sale_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textStyle = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textStyle?.copyWith(
              color: emphasized
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: textStyle?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
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
