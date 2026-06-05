import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../utils/product_sections.dart';
import 'product_list_card.dart';

class ProductSearchResults extends StatelessWidget {
  const ProductSearchResults({
    super.key,
    required this.products,
    required this.query,
  });

  final List<Product> products;
  final String query;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = sortProductsForDisplay(
      filterProductsByQuery(products, query),
    );

    if (filteredProducts.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        message: 'Sin resultados',
        description: 'No se encontraron productos con esa bÃƒÂºsqueda.',
      );
    }

    return Column(
      children: [
        for (final product in filteredProducts) ...[
          ProductListCard(product: product),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
