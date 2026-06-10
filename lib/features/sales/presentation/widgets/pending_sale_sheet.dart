import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/sales_repository.dart';
import '../../providers/sales_provider.dart';

class PendingSaleSheet extends ConsumerStatefulWidget {
  const PendingSaleSheet({
    super.key,
    required this.actor,
    required this.draft,
    required this.subtotal,
  });

  final User actor;
  final SaleRegisterDraft draft;
  final double subtotal;

  static Future<SaleRegisterResult?> show(
    BuildContext context, {
    required User actor,
    required SaleRegisterDraft draft,
    required double subtotal,
  }) {
    return showModalBottomSheet<SaleRegisterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          PendingSaleSheet(actor: actor, draft: draft, subtotal: subtotal),
    );
  }

  @override
  ConsumerState<PendingSaleSheet> createState() => _PendingSaleSheetState();
}

class _PendingSaleSheetState extends ConsumerState<PendingSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _paidAmountController = TextEditingController();
  String _paymentMethod = AppPaymentMethods.cash;
  bool _isSaving = false;

  double get _paidAmount =>
      double.tryParse(_paidAmountController.text.trim()) ?? 0;

  double get _commission =>
      _paidAmount * widget.draft.commissionRates.rateFor(_paymentMethod);

  double get _chargedTotal => _paidAmount + _commission;

  double get _pendingAmount =>
      (widget.subtotal - _paidAmount).clamp(0.0, double.infinity).toDouble();

  @override
  void initState() {
    super.initState();
    _paidAmountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _paidAmountController.removeListener(_onAmountChanged);
    _customerNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _paidAmountController.dispose();
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
                    color: AppColors.borderFor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Venta con pago pendiente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Total de productos: ${_money(widget.subtotal)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderFor(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _customerNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del cliente.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Teléfono opcional',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción opcional',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _paidAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Abono inicial opcional',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount < 0) {
                    return 'Ingresa un monto valido.';
                  }
                  if (amount >= widget.subtotal) {
                    return 'Usa venta normal si se cubre el total.';
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              if (_paidAmount > 0) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Método del abono inicial',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimaryFor(context),
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
              ],
              const SizedBox(height: AppSpacing.lg),
              _PendingSaleSummary(
                paidAmount: _paidAmount,
                commission: _commission,
                chargedTotal: _chargedTotal,
                pendingAmount: _pendingAmount,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isSaving ? 'Guardando...' : 'Registrar pendiente'),
                    const SizedBox(width: AppSpacing.sm),
                    if (_isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.receipt_long_outlined),
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
        .read(salesRepositoryProvider)
        .registerPendingSale(
          actor: widget.actor,
          draft: widget.draft,
          pendingInput: PendingSaleInput(
            customerName: _customerNameController.text,
            customerPhone: _phoneController.text,
            description: _descriptionController.text,
            initialPaidAmount: _paidAmount,
            initialPaymentMethod: _paymentMethod,
          ),
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(result);
  }
}

class _PendingSaleSummary extends StatelessWidget {
  const _PendingSaleSummary({
    required this.paidAmount,
    required this.commission,
    required this.chargedTotal,
    required this.pendingAmount,
  });

  final double paidAmount;
  final double commission;
  final double chargedTotal;
  final double pendingAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bodyBgFor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderFor(context), width: 0.5),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Abono cubierto', value: _money(paidAmount)),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(label: 'Comisión', value: _money(commission)),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(label: 'Cobro inicial', value: _money(chargedTotal)),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(
            label: 'Pendiente',
            value: _money(pendingAmount),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
              color: AppColors.textSecondaryFor(context),
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimaryFor(context),
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
    AppPaymentMethods.terminalCard => 'Débito/Crédito',
    AppPaymentMethods.terminalBonus => 'Bonos',
    _ => method,
  };
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
