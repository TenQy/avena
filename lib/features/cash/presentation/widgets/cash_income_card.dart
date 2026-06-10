import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../utils/cash_formatters.dart';
import 'cash_detail_row.dart';

class CashIncomeCard extends StatelessWidget {
  const CashIncomeCard({super.key, required this.session});

  final CashSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ingresos por método',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            CashDetailRow(
              label: 'Efectivo',
              value: formatMoney(session.cashIncome),
            ),
            const SizedBox(height: AppSpacing.md),
            CashDetailRow(
              label: 'Transferencia',
              value: formatMoney(session.transferIncome),
            ),
            const SizedBox(height: AppSpacing.md),
            CashDetailRow(
              label: 'Terminal',
              value: formatMoney(session.terminalIncome + session.bonusIncome),
            ),
          ],
        ),
      ),
    );
  }
}
