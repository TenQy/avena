import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/settings_local_source.dart';
import '../../providers/settings_provider.dart';
import '../widgets/settings_formatters.dart';
import '../widgets/sheet_handle.dart';

class CommissionRatesSheet extends ConsumerStatefulWidget {
  const CommissionRatesSheet({super.key, required this.initialSettings});

  final AdministrativeSettings initialSettings;

  static Future<void> show(
    BuildContext context,
    AdministrativeSettings settings,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommissionRatesSheet(initialSettings: settings),
    );
  }

  @override
  ConsumerState<CommissionRatesSheet> createState() =>
      _CommissionRatesSheetState();
}

class _CommissionRatesSheetState extends ConsumerState<CommissionRatesSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = TextEditingController();
  final _bonusController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cardController.text = settingsPercentInput(
      widget.initialSettings.commissionRates.terminalCard,
    );
    _bonusController.text = settingsPercentInput(
      widget.initialSettings.commissionRates.terminalBonus,
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _bonusController.dispose();
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
              const SheetHandle(),
              const SizedBox(height: AppSpacing.lg),
              Text('Comisiones', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              _PercentField(controller: _cardController, label: 'Tarjeta'),
              const SizedBox(height: AppSpacing.md),
              _PercentField(controller: _bonusController, label: 'Bonos'),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.save_rounded),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ref
        .read(administrativeSettingsProvider.notifier)
        .saveCommissionRates(
          cardPercent: double.parse(_cardController.text.trim()),
          bonusPercent: double.parse(_bonusController.text.trim()),
        );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }
}

class _PercentField extends StatelessWidget {
  const _PercentField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: '$label (%)',
        prefixIcon: const Icon(Icons.percent_rounded),
      ),
      validator: (value) {
        final percent = double.tryParse(value?.trim() ?? '');
        if (percent == null || percent < 0 || percent > 100) {
          return 'Ingresa un porcentaje entre 0 y 100.';
        }

        return null;
      },
    );
  }
}
