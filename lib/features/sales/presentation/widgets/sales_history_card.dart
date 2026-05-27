import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sales.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../providers/sales_provider.dart';

class SalesHistoryCard extends ConsumerWidget {
  const SalesHistoryCard({super.key, required this.sale, this.onLongPress});

  final Sale sale;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(saleItemsBySaleProvider(sale.id));
    final paymentsState = ref.watch(salePaymentsBySaleProvider(sale.id));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTime(sale.createdAt),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Atendio: ${sale.userNameSnapshot}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(sale.total),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _StatusChip(status: sale.saleStatus),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              itemsState.when(
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          '${_quantity(item.quantity)} ${_unit(item.quantityUnit)} '
                          '${item.productNameSnapshot}  ${_money(item.subtotal)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const _InlineUnavailable(
                  message: 'Productos no disponibles.',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              paymentsState.when(
                data: (payments) => Text(
                  'Pago: ${payments.isEmpty ? 'Pendiente' : payments.map((payment) => paymentMethodLabel(payment.paymentMethod)).join(' + ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) =>
                    const _InlineUnavailable(message: 'Pago no disponible.'),
              ),
              if (sale.pendingAmount > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pendiente: ${_money(sale.pendingAmount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (sale.saleStatus == AppSaleStatuses.cancelled &&
                  sale.cancelReason != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Motivo de cancelacion: ${sale.cancelReason}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SalesHistoryMessageCard extends StatelessWidget {
  const SalesHistoryMessageCard({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.iconInactive),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == AppSaleStatuses.cancelled;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isCancelled ? AppColors.bodyBg : AppColors.headerNav,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        isCancelled ? 'Cancelada' : 'Completada',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isCancelled ? AppColors.textSecondary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineUnavailable extends StatelessWidget {
  const _InlineUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

String paymentMethodLabel(String method) {
  return switch (method) {
    AppPaymentMethods.cash => 'Efectivo',
    AppPaymentMethods.transfer => 'Transferencia',
    AppPaymentMethods.terminalCard => 'Debito/Credito',
    AppPaymentMethods.terminalBonus => 'Bonos',
    _ => 'Otro',
  };
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $period';
}

String _quantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(3);
}

String _unit(String unit) {
  return switch (unit) {
    'kg' => 'kg',
    'g' => 'gr',
    _ => 'pz',
  };
}
