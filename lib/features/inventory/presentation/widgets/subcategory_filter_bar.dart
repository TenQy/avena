import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../utils/product_sections.dart';

class SubcategoryFilterBar extends StatelessWidget {
  const SubcategoryFilterBar({
    super.key,
    required this.sections,
    required this.selectedSubcategoryId,
    required this.onFilterChanged,
  });

  final List<ProductSectionData> sections;
  final String? selectedSubcategoryId;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text('Todas (${totalProducts(sections)})'),
              selected: selectedSubcategoryId == null,
              onSelected: (_) => onFilterChanged(null),
            ),
          ),
          for (final section in sections)
            if (section.subcategory != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  label: Text(
                    '${section.subcategory!.name} (${section.products.length})',
                  ),
                  selected: selectedSubcategoryId == section.subcategory!.id,
                  onSelected: (_) => onFilterChanged(section.subcategory!.id),
                ),
              ),
        ],
      ),
    );
  }
}
