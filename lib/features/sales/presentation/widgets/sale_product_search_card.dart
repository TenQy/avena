import 'package:flutter/material.dart';

import '../../../../core/constants/app_products.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/search_text.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class SaleProductSearchCard extends StatelessWidget {
  const SaleProductSearchCard({
    super.key,
    required this.controller,
    required this.products,
    required this.query,
    required this.onAddProduct,
  });

  final TextEditingController controller;
  final List<Product> products;
  final String query;
  final ValueChanged<Product> onAddProduct;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filterProducts(products, query);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agregar producto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: Icon(Icons.close_rounded),
                        onPressed: controller.clear,
                      ),
              ),
            ),
            if (query.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              if (filteredProducts.isEmpty)
                Text(
                  'Sin resultados.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                  ),
                )
              else
                for (final product in filteredProducts.take(6)) ...[
                  _ProductSearchTile(
                    product: product,
                    onAddProduct: onAddProduct,
                  ),
                  if (product != filteredProducts.take(6).last)
                    Divider(
                      height: AppSpacing.lg,
                      color: AppColors.borderFor(context),
                    ),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductSearchTile extends StatelessWidget {
  const _ProductSearchTile({required this.product, required this.onAddProduct});

  final Product product;
  final ValueChanged<Product> onAddProduct;

  @override
  Widget build(BuildContext context) {
    final unitLabel = product.productType == AppProductTypes.bulk
        ? 'kg'
        : 'unidad';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_money(product.price)} x $unitLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          tooltip: 'Agregar producto',
          onPressed: () => onAddProduct(product),
          icon: Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    );
  }
}

List<Product> _filterProducts(List<Product> products, String query) {
  final cleanQuery = normalizeSearchText(query);
  if (cleanQuery.isEmpty) {
    return const [];
  }

  return products.where((product) {
    if (product.trackStock && (product.stockQuantity ?? 0) <= 0) {
      return false;
    }

    final brand = product.brand;
    return normalizeSearchText(product.name).contains(cleanQuery) ||
        (brand != null && normalizeSearchText(brand).contains(cleanQuery));
  }).toList();
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}
