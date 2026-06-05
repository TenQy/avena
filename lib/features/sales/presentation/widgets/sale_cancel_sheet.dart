import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/sales_repository.dart';
import '../../providers/sales_provider.dart';

class SaleCancelSheet extends ConsumerStatefulWidget {
  const SaleCancelSheet({super.key, required this.actor, required this.sale});

  final User actor;
  final Sale sale;

  static Future<SaleCancelResult?> show(
    BuildContext context, {
    required User actor,
    required Sale sale,
  }) {
    return showModalBottomSheet<SaleCancelResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SaleCancelSheet(actor: actor, sale: sale),
    );
  }

  @override
  ConsumerState<SaleCancelSheet> createState() => _SaleCancelSheetState();
}

class _SaleCancelSheetState extends ConsumerState<SaleCancelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
                'Cancelar venta',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'La venta se marcara como cancelada y se revertiran los '
                'ingresos y existencias correspondientes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _reasonController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo de cancelacion',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el motivo de cancelacion.';
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _cancelSale(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSaving ? null : _cancelSale,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isSaving ? 'Cancelando...' : 'Cancelar venta'),
                    const SizedBox(width: AppSpacing.sm),
                    if (_isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.cancel_outlined),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelSale() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(salesRepositoryProvider)
        .cancelSale(
          actor: widget.actor,
          sale: widget.sale,
          reason: _reasonController.text,
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(result);
  }
}
