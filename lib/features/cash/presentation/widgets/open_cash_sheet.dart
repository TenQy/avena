import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../data/cash_repository.dart';
import '../../providers/cash_provider.dart';
import 'cash_button_content.dart';

class OpenCashSheet extends ConsumerStatefulWidget {
  const OpenCashSheet({super.key});

  @override
  ConsumerState<OpenCashSheet> createState() => _OpenCashSheetState();
}

class _OpenCashSheetState extends ConsumerState<OpenCashSheet> {
  final _amountController = TextEditingController();
  bool _isSaving = false;

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
              'Abrir caja',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Registra el efectivo inicial disponible.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryFor(context)),
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
                labelText: 'Dinero inicial',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              onSubmitted: (_) => _openCash(),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _isSaving ? null : _openCash,
              child: CashButtonContent(
                label: _isSaving ? 'Abriendo...' : 'Abrir caja',
                trailing: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCash() async {
    if (_isSaving) {
      return;
    }

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      Navigator.of(context).pop(OpenCashResult.unauthorized);
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      Navigator.of(context).pop(OpenCashResult.invalidOpeningAmount);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(cashRepositoryProvider)
        .openCashSession(actor: currentUser, openingCashAmount: amount);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(result);
  }
}
