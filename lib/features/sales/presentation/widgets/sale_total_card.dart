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
    required this.canRegister,
    required this.canRegisterPending,
    required this.isRegistering,
    required this.onRegister,
    required this.onRegisterPending,
  });

  final double subtotal;
  final double commission;
  final bool showCashPayment;
  final bool canRegister;
  final bool canRegisterPending;
  final bool isRegistering;
  final VoidCallback onRegister;
  final VoidCallback onRegisterPending;

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
            _TotalRow(label: 'Comisión', value: _money(widget.commission)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderFor(context),
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
              onPressed: widget.canRegister && !widget.isRegistering
                  ? widget.onRegister
                  : null,
              child: widget.isRegistering
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const _ButtonContent(
                      label: 'Registrar venta',
                      icon: Icons.point_of_sale_rounded,
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: widget.canRegisterPending && !widget.isRegistering
                  ? widget.onRegisterPending
                  : null,
              child: const _ButtonContent(
                label: 'Dejar pago pendiente',
                icon: Icons.receipt_long_outlined,
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
                  ? AppColors.textPrimaryFor(context)
                  : AppColors.textSecondaryFor(context),
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: textStyle?.copyWith(
            color: AppColors.textPrimaryFor(context),
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
