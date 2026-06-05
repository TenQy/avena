import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../utils/product_sections.dart';
import 'product_list_card.dart';

class ProductSection extends StatelessWidget {
  const ProductSection({
    super.key,
    required this.section,
    required this.onProductTap,
    this.onProductLongPress,
    this.onDeleteSubcategory,
  });

  final ProductSectionData section;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product>? onProductLongPress;
  final VoidCallback? onDeleteSubcategory;

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderFor(context);
    final iconInactive = AppColors.iconInactiveFor(context);
    final title = section.subcategory?.name ?? 'Sin subcategorÃƒÂ­a';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '$title (${section.products.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: border,
              ),
            ),
            if (onDeleteSubcategory != null) ...[
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Eliminar subcategorÃƒÂ­a',
                icon: Icon(Icons.delete_outline_rounded),
                color: iconInactive,
                onPressed: onDeleteSubcategory,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (section.products.isEmpty)
          const EmptyProductCard()
        else
          for (final product in section.products) ...[
            ProductListCard(
              product: product,
              onTap: () => onProductTap(product),
              onLongPress: onProductLongPress == null
                  ? null
                  : () => onProductLongPress!(product),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class EmptyProductCard extends StatelessWidget {
  const EmptyProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Sin productos en esta subcategorÃƒÂ­a.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
      ),
    );
  }
}
