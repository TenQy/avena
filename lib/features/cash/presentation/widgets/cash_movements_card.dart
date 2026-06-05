import 'package:flutter/material.dart';

import '../../../../core/constants/app_cash.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../utils/cash_formatters.dart';

class CashMovementsCard extends StatelessWidget {
  const CashMovementsCard({super.key, required this.movements});

  final List<CashMovement> movements;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Movimientos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (movements.isEmpty)
              Text(
                'Aun no hay retiros ni depositos.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              )
            else
              for (final movement in movements) ...[
                _MovementTile(movement: movement),
                if (movement != movements.last)
                  Divider(height: AppSpacing.lg, color: AppColors.borderFor(context)),
              ],
          ],
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final CashMovement movement;

  bool get _isDeposit => movement.type == AppCashMovementTypes.deposit;

  @override
  Widget build(BuildContext context) {
    final title = _isDeposit ? 'Deposito' : 'Retiro';
    final prefix = _isDeposit ? '+' : '-';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bodyBgFor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderFor(context), width: 0.5),
          ),
          child: Icon(
            _isDeposit
                ? Icons.add_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            color: AppColors.iconInactiveFor(context),
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                movement.reason,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatCashDateTime(movement.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.iconInactiveFor(context)),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '$prefix${formatMoney(movement.amount)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
