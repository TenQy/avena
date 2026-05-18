import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import 'category_card.dart';

class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    required this.onCategoryLongPress,
  });

  final List<Category> categories;
  final ValueChanged<Category> onCategoryTap;
  final ValueChanged<Category> onCategoryLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        final itemHeight = itemWidth / 1.35;

        return Column(
          children: [
            SizedBox(
              height: itemHeight,
              child: CategoryCard(
                category: categories.first,
                isMain: true,
                onTap: () => onCategoryTap(categories.first),
                onLongPress: () => onCategoryLongPress(categories.first),
              ),
            ),
            if (categories.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length - 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index + 1];

                  return CategoryCard(
                    category: category,
                    isMain: false,
                    onTap: () => onCategoryTap(category),
                    onLongPress: () => onCategoryLongPress(category),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
