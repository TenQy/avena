import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class SaleTotalCard extends StatelessWidget {
  const SaleTotalCard({
    super.key,
    required this.subtotal,
    required this.commission,
  });

  final double subtotal;
  final double commission;

  double get total => subtotal + commission;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TotalRow(label: 'Subtotal', value: _money(subtotal)),
            const SizedBox(height: AppSpacing.md),
            _TotalRow(label: 'Comision', value: _money(commission)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.border,
              ),
            ),
            _TotalRow(label: 'Total', value: _money(total), emphasized: true),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: null,
              child: const _ButtonContent(
                label: 'Registrar venta',
                icon: Icons.point_of_sale_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textStyle = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textStyle?.copyWith(
              color: emphasized
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: textStyle?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        const SizedBox(width: AppSpacing.sm),
        Icon(icon),
      ],
    );
  }
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}
