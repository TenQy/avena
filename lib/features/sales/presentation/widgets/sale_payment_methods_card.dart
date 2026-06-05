import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class SalePaymentMethodsCard extends StatelessWidget {
  const SalePaymentMethodsCard({
    super.key,
    required this.selectedMethod,
    required this.mixedPayments,
    required this.subtotal,
    required this.total,
    required this.mixedTotal,
    required this.onMethodSelected,
    required this.onMixedPaymentChanged,
  });

  final String selectedMethod;
  final Map<String, double> mixedPayments;
  final double subtotal;
  final double total;
  final double mixedTotal;
  final ValueChanged<String> onMethodSelected;
  final void Function(String method, double amount) onMixedPaymentChanged;

  bool get _isMixed => selectedMethod == AppPaymentMethods.mixed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Metodo de pago',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final method in AppPaymentMethods.all)
                  ChoiceChip(
                    label: Text(_paymentLabel(method)),
                    selected: selectedMethod == method,
                    showCheckmark: false,
                    onSelected: (_) => onMethodSelected(method),
                    backgroundColor: AppColors.bodyBgFor(context),
                    selectedColor: AppColors.headerNavFor(context),
                    side: BorderSide(color: AppColors.borderFor(context), width: 0.5),
                    labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selectedMethod == method
                          ? AppColors.textPrimaryFor(context)
                          : AppColors.textSecondaryFor(context),
                      fontWeight: selectedMethod == method
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
              ],
            ),
            if (_isMixed) ...[
              const SizedBox(height: AppSpacing.lg),
              _MixedPaymentInputs(
                payments: mixedPayments,
                subtotal: subtotal,
                onChanged: onMixedPaymentChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              _MixedPaymentSummary(total: total, mixedTotal: mixedTotal),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Comisiones: debito/credito 5%, bonos 6.5%.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryFor(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MixedPaymentInputs extends StatelessWidget {
  const _MixedPaymentInputs({
    required this.payments,
    required this.subtotal,
    required this.onChanged,
  });

  final Map<String, double> payments;
  final double subtotal;
  final void Function(String method, double amount) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final method in AppPaymentMethods.mixable) ...[
          Builder(
            builder: (context) {
              final remainingCharge = _remainingChargeFor(method);

              return TextFormField(
                key: ValueKey('mixed-$method'),
                initialValue: _initialValue(payments[method]),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: _paymentLabel(method),
                  hintText: _money(remainingCharge),
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryFor(context).withValues(alpha: 0.55),
                  ),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                onChanged: (value) {
                  onChanged(method, double.tryParse(value.trim()) ?? 0);
                },
              );
            },
          ),
          if (method != AppPaymentMethods.mixable.last)
            const SizedBox(height: AppSpacing.md),
        ],
        Text(
          'Debito/credito y bonos agregan comision al total cobrado.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryFor(context)),
        ),
      ],
    );
  }

  double _remainingChargeFor(String method) {
    final paidWithOtherMethods = payments.entries.fold(0.0, (total, entry) {
      if (entry.key == method) {
        return total;
      }

      return total + entry.value;
    });
    final remainingBase = (subtotal - paidWithOtherMethods)
        .clamp(0.0, double.infinity)
        .toDouble();

    return remainingBase * (1 + AppPaymentCommissions.rateFor(method));
  }
}

class _MixedPaymentSummary extends StatelessWidget {
  const _MixedPaymentSummary({required this.total, required this.mixedTotal});

  final double total;
  final double mixedTotal;

  @override
  Widget build(BuildContext context) {
    final remaining = total - mixedTotal;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bodyBgFor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderFor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryRow(label: 'Total venta', value: _money(total)),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(label: 'Pagado con comision', value: _money(mixedTotal)),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(label: 'Restante', value: _money(remaining)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryFor(context)),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _paymentLabel(String method) {
  return switch (method) {
    AppPaymentMethods.cash => 'Efectivo',
    AppPaymentMethods.transfer => 'Transferencia',
    AppPaymentMethods.terminalCard => 'Debito/Credito',
    AppPaymentMethods.terminalBonus => 'Bonos',
    AppPaymentMethods.mixed => 'Mixto',
    _ => method,
  };
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

String _initialValue(double? value) {
  if (value == null || value <= 0) {
    return '';
  }

  return value.toStringAsFixed(2);
}
