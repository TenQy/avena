import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import 'cash_button_content.dart';
import 'cash_icon_header.dart';

class ClosedCashCard extends StatelessWidget {
  const ClosedCashCard({super.key, required this.onOpenCash});

  final VoidCallback onOpenCash;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CashIconHeader(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Caja cerrada',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay una caja abierta.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Abre caja registrando el efectivo inicial.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onOpenCash,
              child: const CashButtonContent(
                label: 'Abrir caja',
                trailing: Icon(Icons.lock_open_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
