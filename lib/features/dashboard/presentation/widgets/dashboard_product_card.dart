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
    required this.topProducts,
    this.showSaleCount = false,
  });

  final IconData icon;
  final String title;
  final String emptyText;
  final DashboardProductMetric? metric;
  final List<DashboardProductMetric> topProducts;
  final bool showSaleCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final product = metric;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: topProducts.isEmpty ? null : () => _showTopProductsSheet(context),
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
                        _metricSummary(product),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (topProducts.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(Icons.chevron_right_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTopProductsSheet(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                for (var index = 0; index < topProducts.length; index++) ...[
                  _TopProductRow(
                    position: index + 1,
                    product: topProducts[index],
                    summary: _metricSummary(topProducts[index]),
                  ),
                  if (index < topProducts.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _metricSummary(DashboardProductMetric product) {
    if (showSaleCount) {
      return 'Aparece en ${product.saleCount} ventas - ${_quantity(product)} vendidos';
    }

    return '${_money(product.income)} - ${_quantity(product)} vendidos';
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.position,
    required this.product,
    required this.summary,
  });

  final int position;
  final DashboardProductMetric product;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text('$position.', style: textTheme.labelLarge),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(summary, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
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
