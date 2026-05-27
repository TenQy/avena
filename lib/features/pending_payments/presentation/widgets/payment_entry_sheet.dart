import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/pending_payments_repository.dart';
import '../../providers/pending_payments_provider.dart';

class PaymentEntrySheet extends ConsumerStatefulWidget {
  const PaymentEntrySheet({
    super.key,
    required this.actor,
    required this.payment,
  });

  final User actor;
  final PendingPayment payment;

  static Future<PendingPaymentEntryResult?> show(
    BuildContext context, {
    required User actor,
    required PendingPayment payment,
  }) {
    return showModalBottomSheet<PendingPaymentEntryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentEntrySheet(actor: actor, payment: payment),
    );
  }

  @override
  ConsumerState<PaymentEntrySheet> createState() => _PaymentEntrySheetState();
}

class _PaymentEntrySheetState extends ConsumerState<PaymentEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMethod = AppPaymentMethods.cash;
  bool _isSaving = false;

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  double get _commission =>
      _amount * AppPaymentCommissions.rateFor(_paymentMethod);

  double get _chargedTotal => _amount + _commission;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Registrar abono',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.payment.customerName} - Pendiente: ${_money(widget.payment.remainingAmount)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, thickness: 0.5, color: AppColors.border),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Saldo a cubrir',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto mayor a cero.';
                  }
                  if (amount > widget.payment.remainingAmount) {
                    return 'El monto supera el saldo pendiente.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Metodo de pago',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final method in AppPaymentMethods.mixable)
                    ChoiceChip(
                      label: Text(_paymentMethodLabel(method)),
                      selected: _paymentMethod == method,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _paymentMethod = method;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _EntryChargeSummary(
                coveredAmount: _amount,
                commission: _commission,
                chargedTotal: _chargedTotal,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Nota opcional',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isSaving ? 'Guardando...' : 'Registrar abono'),
                    const SizedBox(width: AppSpacing.sm),
                    if (_isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.payments_outlined),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(pendingPaymentsRepositoryProvider)
        .createPaymentEntry(
          actor: widget.actor,
          payment: widget.payment,
          amount: double.parse(_amountController.text.trim()),
          paymentMethod: _paymentMethod,
          note: _noteController.text,
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(result);
  }
}

class _EntryChargeSummary extends StatelessWidget {
  const _EntryChargeSummary({
    required this.coveredAmount,
    required this.commission,
    required this.chargedTotal,
  });

  final double coveredAmount;
  final double commission;
  final double chargedTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bodyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _ChargeRow(label: 'Saldo a cubrir', value: _money(coveredAmount)),
          const SizedBox(height: AppSpacing.sm),
          _ChargeRow(label: 'Comision', value: _money(commission)),
          const SizedBox(height: AppSpacing.sm),
          _ChargeRow(
            label: 'Total a cobrar',
            value: _money(chargedTotal),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  const _ChargeRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _paymentMethodLabel(String method) {
  return switch (method) {
    AppPaymentMethods.cash => 'Efectivo',
    AppPaymentMethods.transfer => 'Transferencia',
    AppPaymentMethods.terminalCard => 'Debito/Credito',
    AppPaymentMethods.terminalBonus => 'Bonos',
    _ => method,
  };
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
