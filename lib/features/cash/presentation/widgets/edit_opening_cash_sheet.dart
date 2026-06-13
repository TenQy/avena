import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../data/cash_repository.dart';
import '../../providers/cash_provider.dart';
import 'cash_button_content.dart';

class EditOpeningCashSheet extends ConsumerStatefulWidget {
  const EditOpeningCashSheet({super.key, required this.session});

  final CashSession session;

  @override
  ConsumerState<EditOpeningCashSheet> createState() =>
      _EditOpeningCashSheetState();
}

class _EditOpeningCashSheetState extends ConsumerState<EditOpeningCashSheet> {
  late final TextEditingController _amountController;
  bool _isSaving = false;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.session.openingCashAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl + bottomInset,
        ),
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
              'Editar dinero inicial',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'El cambio ajustara tambien la caja fisica esperada.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Dinero inicial',
                helperText: 'Monto maximo: \$999999.00',
                errorText: _amountError,
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: CashButtonContent(
                label: _isSaving ? 'Guardando...' : 'Guardar cambio',
                trailing: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    final amountError = _validateAmount(amount);
    if (amountError != null) {
      setState(() {
        _amountError = amountError;
      });
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Editar dinero inicial',
      message: 'Se cambiara el dinero inicial de caja y se registrara en logs.',
      confirmLabel: 'Guardar',
      icon: Icons.edit_rounded,
    );

    if (!mounted || !confirmed) {
      return;
    }

    final actor = ref.read(currentUserProvider).valueOrNull;
    if (actor == null) {
      Navigator.of(context).pop(UpdateOpeningCashResult.unauthorized);
      return;
    }

    setState(() {
      _isSaving = true;
      _amountError = null;
    });

    final result = await ref
        .read(cashRepositoryProvider)
        .updateOpeningCashAmount(
          actor: actor,
          session: widget.session,
          openingCashAmount: amount!,
        );

    if (!mounted) {
      return;
    }

    if (result == UpdateOpeningCashResult.success ||
        result == UpdateOpeningCashResult.unauthorized ||
        result == UpdateOpeningCashResult.sessionNotFound) {
      Navigator.of(context).pop(result);
      return;
    }

    setState(() {
      _isSaving = false;
      _amountError = switch (result) {
        UpdateOpeningCashResult.invalidAmount =>
          'Ingresa un monto inicial valido.',
        UpdateOpeningCashResult.amountTooHigh =>
          'El monto maximo es \$999999.00.',
        _ => null,
      };
    });
  }

  String? _validateAmount(double? amount) {
    if (amount == null || !amount.isFinite || amount < 0) {
      return 'Ingresa un monto inicial valido.';
    }

    if (amount > CashRepository.maxCashOperationAmount) {
      return 'El monto maximo es \$999999.00.';
    }

    final expectedCashAmount =
        widget.session.expectedCashAmount +
        (amount - widget.session.openingCashAmount);
    if (expectedCashAmount < 0) {
      return 'La caja esperada no puede quedar negativa.';
    }

    return null;
  }
}
