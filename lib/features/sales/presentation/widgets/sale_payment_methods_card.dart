import 'package:flutter/material.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class SalePaymentMethodsCard extends StatelessWidget {
  const SalePaymentMethodsCard({super.key});

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
                  _PaymentChip(label: _paymentLabel(method)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Comisiones: terminal debito/credito 5%, bonos 6.5%.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.bodyBg,
      side: const BorderSide(color: AppColors.border, width: 0.5),
      labelStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

String _paymentLabel(String method) {
  return switch (method) {
    AppPaymentMethods.cash => 'Efectivo',
    AppPaymentMethods.transfer => 'Transferencia',
    AppPaymentMethods.terminalCard => 'Terminal',
    AppPaymentMethods.terminalBonus => 'Bonos',
    AppPaymentMethods.mixed => 'Mixto',
    _ => method,
  };
}
