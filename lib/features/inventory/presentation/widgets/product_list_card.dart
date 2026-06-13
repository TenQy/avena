import 'package:flutter/material.dart';

import '../../../../core/constants/app_products.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class ProductListCard extends StatelessWidget {
  const ProductListCard({
    super.key,
    required this.product,
    this.onTap,
    this.onLongPress,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final price = '\$${product.price.toStringAsFixed(2)}';
    final priceUnitLabel = product.productType == AppProductTypes.bulk
        ? 'kg'
        : 'unidad';
    final headerNav = AppColors.headerNavFor(context);
    final border = AppColors.borderFor(context);
    final iconInactive = AppColors.iconInactiveFor(context);
    final textPrimary = AppColors.textPrimaryFor(context);
    final textSecondary = AppColors.textSecondaryFor(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: headerNav,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border, width: 0.5),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: iconInactive,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.brand != null && product.brand!.isNotEmpty)
                      Text(
                        product.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: textSecondary),
                      ),
                    if (product.trackStock)
                      Text(
                        'Stock: ${_formatStock(product)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(text: price),
                    TextSpan(
                      text: ' x $priceUnitLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatStock(Product product) {
  final quantity = product.stockQuantity ?? 0;
  if (product.productType == AppProductTypes.bulk) {
    return _formatBulkQuantity(quantity);
  }

  final units = quantity.truncate();
  return '$units ${units == 1 ? 'unidad' : 'unidades'}';
}

String _formatBulkQuantity(double kilograms) {
  if (kilograms > 0 && kilograms < 1) {
    final grams = (kilograms * 1000).round();
    return '$grams g';
  }

  final formatted = kilograms
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return '$formatted kg';
}
