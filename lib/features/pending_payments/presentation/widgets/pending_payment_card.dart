import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_pending_payments.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../providers/pending_payments_provider.dart';

class PendingPaymentCard extends ConsumerStatefulWidget {
  const PendingPaymentCard({
    super.key,
    required this.payment,
    this.onRegisterEntry,
  });

  final PendingPayment payment;
  final VoidCallback? onRegisterEntry;

  @override
  ConsumerState<PendingPaymentCard> createState() => _PendingPaymentCardState();
}

class _PendingPaymentCardState extends ConsumerState<PendingPaymentCard> {
  bool _showEntries = false;

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final entriesState = _showEntries
        ? ref.watch(pendingPaymentEntriesProvider(payment.id))
        : null;
    final progress = payment.totalAmount <= 0
        ? 0.0
        : (payment.paidAmount / payment.totalAmount).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    payment.customerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _PendingPaymentStatusChip(status: payment.status),
              ],
            ),
            if (payment.customerPhone != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                payment.customerPhone!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
            if (payment.description != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                payment.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(
                    label: 'Total',
                    value: _money(payment.totalAmount),
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: 'Abonado',
                    value: _money(payment.paidAmount),
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: 'Saldo',
                    value: _money(payment.remainingAmount),
                    emphasized: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: AppColors.bodyBgFor(context),
              color: AppColors.textSecondaryFor(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Creado: ${_dateTime(payment.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showEntries = !_showEntries;
                      });
                    },
                    child: Text(
                      _showEntries ? 'Ocultar historial' : 'Ver historial',
                    ),
                  ),
                ),
                if (widget.onRegisterEntry != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: widget.onRegisterEntry,
                      child: const Text('Abonar'),
                    ),
                  ),
                ],
              ],
            ),
            if (_showEntries) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderFor(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Historial de abonos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              entriesState!.when(
                data: (entries) => _EntriesList(entries: entries),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => Text(
                  'No se pudo cargar el historial.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EntriesList extends StatelessWidget {
  const _EntriesList({required this.entries});

  final List<PendingPaymentEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Text(
        'Aún no hay abonos registrados.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondaryFor(context),
        ),
      );
    }

    return Column(
      children: [
        for (final entry in entries) ...[
          _PaymentEntryRow(entry: entry),
          if (entry != entries.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _PaymentEntryRow extends StatelessWidget {
  const _PaymentEntryRow({required this.entry});

  final PendingPaymentEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bodyBgFor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _paymentMethodLabel(entry.paymentMethod),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.note != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _dateTime(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                ),
                if (AppPaymentCommissions.rateFor(entry.paymentMethod) > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Cubre ${_money(entry.amount)} + comisión '
                    '${_money(_entryCommission(entry))}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _money(_entryChargedAmount(entry)),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimaryFor(context),
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PendingPaymentStatusChip extends StatelessWidget {
  const _PendingPaymentStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.headerNavFor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderFor(context), width: 0.5),
      ),
      child: Text(
        _statusLabel(status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimaryFor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    AppPendingPaymentStatuses.partial => 'Parcial',
    AppPendingPaymentStatuses.completed => 'Completado',
    _ => 'Pendiente',
  };
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

double _entryCommission(PendingPaymentEntry entry) {
  return double.parse(
    (entry.amount * AppPaymentCommissions.rateFor(entry.paymentMethod))
        .toStringAsFixed(2),
  );
}

double _entryChargedAmount(PendingPaymentEntry entry) {
  return double.parse(
    (entry.amount + _entryCommission(entry)).toStringAsFixed(2),
  );
}

String _paymentMethodLabel(String method) {
  return switch (method) {
    AppPaymentMethods.cash => 'Efectivo',
    AppPaymentMethods.transfer => 'Transferencia',
    AppPaymentMethods.terminalCard => 'Débito/Crédito',
    AppPaymentMethods.terminalBonus => 'Bonos',
    _ => method,
  };
}

String _dateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';

  return '$day/$month/${value.year} $hour:$minute $period';
}
