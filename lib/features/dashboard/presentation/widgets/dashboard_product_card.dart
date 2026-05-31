import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/dashboard_repository.dart';

class DashboardProductCard extends StatelessWidget {
  const DashboardProductCard({
    super.key,
    required this.icon,
    required this.title,
    required this.emptyText,
    required this.metric,
    this.showSaleCount = false,
  });

  final IconData icon;
  final String title;
  final String emptyText;
  final DashboardProductMetric? metric;
  final bool showSaleCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final product = metric;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.headerNav,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.iconInactive),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    product?.name ?? emptyText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  if (product != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      showSaleCount
                          ? 'Aparece en ${product.saleCount} ventas · ${_quantity(product)} vendidos'
                          : '${_money(product.income)} · ${_quantity(product)} vendidos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _quantity(DashboardProductMetric product) {
  final value = product.quantity;

  if (product.isBulk) {
    return '${value.toStringAsFixed(3)} kg';
  }

  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(3);
}
