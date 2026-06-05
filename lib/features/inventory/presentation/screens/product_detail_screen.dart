import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_products.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../providers/inventory_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final subcategoriesState = ref.watch(
      subcategoriesByCategoryProvider(product.categoryId),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              104,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductSummary(product: product),
                  const SizedBox(height: AppSpacing.lg),
                  _ProductInfoSection(
                    product: product,
                    categoryName: _categoryName(categoriesState),
                    subcategoryName: _subcategoryName(subcategoriesState),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (product.productType == AppProductTypes.bulk)
                    _BulkPortionsSection(product: product)
                  else
                    _UnitPriceSection(product: product),
                  const SizedBox(height: AppSpacing.lg),
                  _StockSection(product: product),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryName(AsyncValue<List<Category>> state) {
    return state.maybeWhen(
      data: (categories) {
        for (final category in categories) {
          if (category.id == product.categoryId) {
            return category.name;
          }
        }

        return 'No disponible';
      },
      orElse: () => 'Cargando...',
    );
  }

  String _subcategoryName(AsyncValue<List<Subcategory>> state) {
    if (product.subcategoryId == null) {
      return 'Sin subcategorÃƒÂ­a';
    }

    return state.maybeWhen(
      data: (subcategories) {
        for (final subcategory in subcategories) {
          if (subcategory.id == product.subcategoryId) {
            return subcategory.name;
          }
        }

        return 'No disponible';
      },
      orElse: () => 'Cargando...',
    );
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final unitLabel = product.productType == AppProductTypes.bulk
        ? 'kg'
        : 'unidad';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.headerNavFor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderFor(context), width: 0.5),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: AppColors.iconInactiveFor(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Text(
                      product.brand!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryFor(context),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(text: _money(product.price)),
                  TextSpan(
                    text: ' x $unitLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  const _ProductInfoSection({
    required this.product,
    required this.categoryName,
    required this.subcategoryName,
  });

  final Product product;
  final String categoryName;
  final String subcategoryName;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'InformaciÃƒÂ³n',
      children: [
        _DetailRow(label: 'CategorÃƒÂ­a', value: categoryName),
        _DetailRow(label: 'SubcategorÃƒÂ­a', value: subcategoryName),
        _DetailRow(
          label: 'Tipo',
          value: product.productType == AppProductTypes.bulk
              ? 'Granel'
              : 'Unidad',
        ),
        if (product.description != null && product.description!.isNotEmpty)
          _DetailRow(label: 'DescripciÃƒÂ³n', value: product.description!),
      ],
    );
  }
}

class _BulkPortionsSection extends StatelessWidget {
  const _BulkPortionsSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Porciones',
      children: [
        for (final portion in AppBulkPortions.standard)
          _DetailRow(
            label: portion.label,
            value: _money(product.price * portion.kilogramFactor),
          ),
      ],
    );
  }
}

class _UnitPriceSection extends StatelessWidget {
  const _UnitPriceSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Precio',
      children: [_DetailRow(label: 'Unidad', value: _money(product.price))],
    );
  }
}

class _StockSection extends StatelessWidget {
  const _StockSection({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Stock',
      children: [
        _DetailRow(
          label: 'Control de stock',
          value: product.trackStock ? 'Activado' : 'Sin control',
        ),
        if (product.trackStock)
          _DetailRow(
            label: 'Cantidad actual',
            value: _formatQuantity(product.stockQuantity ?? 0),
          ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const EmptyState(
        icon: Icons.info_outline_rounded,
        message: 'Sin informaciÃƒÂ³n',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            for (final child in children) child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

String _formatQuantity(double value) {
  final text = value.toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}
