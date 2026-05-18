import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../utils/product_sections.dart';
import 'product_section.dart';
import 'subcategory_filter_bar.dart';

class CategoryProductList extends StatelessWidget {
  const CategoryProductList({
    super.key,
    required this.subcategories,
    required this.products,
    required this.searchQuery,
    required this.selectedSubcategoryId,
    required this.onFilterChanged,
    required this.onDeleteSubcategory,
    required this.onProductTap,
    required this.onProductLongPress,
  });

  final List<Subcategory> subcategories;
  final List<Product> products;
  final String searchQuery;
  final String? selectedSubcategoryId;
  final ValueChanged<String?> onFilterChanged;
  final ValueChanged<Subcategory> onDeleteSubcategory;
  final ValueChanged<Product> onProductTap;
  final ValueChanged<Product> onProductLongPress;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = filterProductsByQuery(products, searchQuery);
    final sections = buildProductSections(subcategories, filteredProducts);
    final visibleSections = selectedSubcategoryId == null
        ? sections
        : sections
              .where(
                (section) => section.subcategory?.id == selectedSubcategoryId,
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubcategoryFilterBar(
          sections: sections,
          selectedSubcategoryId: selectedSubcategoryId,
          onFilterChanged: onFilterChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (visibleSections.isEmpty)
          const EmptyState(
            icon: Icons.inventory_2_rounded,
            message: 'Sin productos aún',
            description: 'Los productos de esta categoría aparecerán aquí.',
          )
        else
          for (final section in visibleSections) ...[
            ProductSection(
              section: section,
              onProductTap: onProductTap,
              onProductLongPress: onProductLongPress,
              onDeleteSubcategory: section.subcategory == null
                  ? null
                  : () => onDeleteSubcategory(section.subcategory!),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}
