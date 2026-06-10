import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../data/cash_repository.dart';
import '../../providers/cash_provider.dart';
import 'cash_button_content.dart';

class CashMovementSheet extends ConsumerStatefulWidget {
  const CashMovementSheet({
    super.key,
    required this.session,
    required this.type,
  });

  final CashSession session;
  final CashMovementType type;

  @override
  ConsumerState<CashMovementSheet> createState() => _CashMovementSheetState();
}

class _CashMovementSheetState extends ConsumerState<CashMovementSheet> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSaving = false;

  bool get _isDeposit => widget.type == CashMovementType.deposit;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final title = _isDeposit ? 'Deposito' : 'Retiro';
    final description = _isDeposit
        ? 'Registra efectivo agregado a caja.'
        : 'Registra efectivo retirado de caja.';

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
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
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
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reasonController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              onSubmitted: (_) => _saveMovement(),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _isSaving ? null : _saveMovement,
              child: CashButtonContent(
                label: _isSaving ? 'Guardando...' : 'Registrar $title',
                trailing: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isDeposit
                            ? Icons.add_circle_outline_rounded
                            : Icons.remove_circle_outline_rounded,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMovement() async {
    if (_isSaving) {
      return;
    }

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      Navigator.of(context).pop(CashMovementResult.unauthorized);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      Navigator.of(context).pop(CashMovementResult.invalidAmount);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(cashRepositoryProvider)
        .createMovement(
          actor: currentUser,
          session: widget.session,
          type: widget.type,
          amount: amount,
          reason: _reasonController.text,
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(result);
  }
}
