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
    required this.commissionRates,
    required this.onMethodSelected,
    required this.onMixedPaymentChanged,
  });

  final String selectedMethod;
  final Map<String, double> mixedPayments;
  final double subtotal;
  final double total;
  final double mixedTotal;
  final PaymentCommissionRates commissionRates;
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
              'Método de pago',
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
                    side: BorderSide(
                      color: AppColors.borderFor(context),
                      width: 0.5,
                    ),
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
                commissionRates: commissionRates,
                onChanged: onMixedPaymentChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              _MixedPaymentSummary(total: total, mixedTotal: mixedTotal),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Comisiones: débito/crédito ${_percent(commissionRates.terminalCard)}, bonos ${_percent(commissionRates.terminalBonus)}.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
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
    required this.commissionRates,
    required this.onChanged,
  });

  final Map<String, double> payments;
  final double subtotal;
  final PaymentCommissionRates commissionRates;
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
                initialValue: _initialChargeValue(method),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: _paymentLabel(method),
                  hintText: _money(remainingCharge),
                  helperText: 'Restante sugerido: ${_money(remainingCharge)}',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryFor(
                      context,
                    ).withValues(alpha: 0.55),
                  ),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                onChanged: (value) {
                  onChanged(method, _baseAmountForInput(method, value));
                },
              );
            },
          ),
          if (method != AppPaymentMethods.mixable.last)
            const SizedBox(height: AppSpacing.md),
        ],
        Text(
          'Débito/crédito y bonos agregan comisión al total cobrado.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
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

    return remainingBase * (1 + commissionRates.rateFor(method));
  }

  String _initialChargeValue(String method) {
    final baseAmount = payments[method];
    if (baseAmount == null || baseAmount <= 0) {
      return '';
    }

    return _roundMoney(
      baseAmount * (1 + commissionRates.rateFor(method)),
    ).toStringAsFixed(2);
  }

  double _baseAmountForInput(String method, String value) {
    final chargedAmount = double.tryParse(value.trim()) ?? 0;
    if (chargedAmount <= 0) {
      return 0;
    }

    final rate = commissionRates.rateFor(method);
    if (rate == 0) {
      return chargedAmount;
    }

    return _roundMoney(chargedAmount / (1 + rate));
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
          _SummaryRow(label: 'Pagado con comisión', value: _money(mixedTotal)),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryFor(context),
            ),
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
    AppPaymentMethods.terminalCard => 'Débito/Crédito',
    AppPaymentMethods.terminalBonus => 'Bonos',
    AppPaymentMethods.mixed => 'Mixto',
    _ => method,
  };
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));

String _percent(double rate) {
  final value = rate * 100;
  return value == value.roundToDouble()
      ? '${value.toStringAsFixed(0)}%'
      : '${value.toStringAsFixed(1)}%';
}
