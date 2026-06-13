import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../utils/cash_formatters.dart';
import 'cash_button_content.dart';
import 'cash_detail_row.dart';
import 'cash_icon_header.dart';

class OpenCashCard extends StatelessWidget {
  const OpenCashCard({
    super.key,
    required this.session,
    required this.onWithdrawal,
    required this.onDeposit,
    required this.onEditOpeningCash,
    required this.onCloseCash,
  });

  final CashSession session;
  final VoidCallback onWithdrawal;
  final VoidCallback onDeposit;
  final VoidCallback onEditOpeningCash;
  final VoidCallback onCloseCash;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CashIconHeader(
              icon: Icons.lock_open_rounded,
              label: 'Caja abierta',
            ),
            const SizedBox(height: AppSpacing.lg),
            CashDetailRow(
              label: 'Dinero inicial',
              value: formatMoney(session.openingCashAmount),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEditOpeningCash,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CashDetailRow(
              label: 'Caja fisica esperada',
              value: formatMoney(session.expectedCashAmount),
            ),
            const SizedBox(height: AppSpacing.md),
            CashDetailRow(
              label: 'Apertura',
              value: formatCashDateTime(session.openedAt),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onWithdrawal,
                    child: const CashButtonContent(
                      label: 'Retiro',
                      trailing: Icon(Icons.remove_circle_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDeposit,
                    child: const CashButtonContent(
                      label: 'Deposito',
                      trailing: Icon(Icons.add_circle_outline_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onCloseCash,
              child: const CashButtonContent(
                label: 'Cerrar caja',
                trailing: Icon(Icons.lock_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
