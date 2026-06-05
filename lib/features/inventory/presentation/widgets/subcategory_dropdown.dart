import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/inventory_provider.dart';

class SubcategoryDropdown extends ConsumerWidget {
  const SubcategoryDropdown({
    super.key,
    required this.categoryId,
    required this.selectedSubcategoryId,
    required this.enabled,
    required this.onChanged,
  });

  final String? categoryId;
  final String? selectedSubcategoryId;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = this.categoryId;

    if (categoryId == null) {
      return DropdownButtonFormField<String>(
        key: const ValueKey('subcategory-disabled'),
        initialValue: null,
        decoration: const InputDecoration(
          labelText: 'SubcategorÃƒÂ­a opcional',
          prefixIcon: Icon(Icons.folder_rounded),
        ),
        items: const [],
        onChanged: null,
      );
    }

    final subcategoriesState = ref.watch(
      subcategoriesByCategoryProvider(categoryId),
    );

    return subcategoriesState.when(
      data: (subcategories) {
        final value =
            subcategories.any(
              (subcategory) => subcategory.id == selectedSubcategoryId,
            )
            ? selectedSubcategoryId
            : null;

        return DropdownButtonFormField<String>(
          key: ValueKey('subcategory-$categoryId-$value'),
          initialValue: value,
          decoration: const InputDecoration(
            labelText: 'SubcategorÃƒÂ­a opcional',
            prefixIcon: Icon(Icons.folder_rounded),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Sin subcategorÃƒÂ­a'),
            ),
            for (final subcategory in subcategories)
              DropdownMenuItem(
                value: subcategory.id,
                child: Text(subcategory.name),
              ),
          ],
          onChanged: enabled ? onChanged : null,
        );
      },
      loading: () => DropdownButtonFormField<String>(
        key: ValueKey('subcategory-loading-$categoryId'),
        initialValue: null,
        decoration: const InputDecoration(
          labelText: 'SubcategorÃƒÂ­a opcional',
          prefixIcon: Icon(Icons.folder_rounded),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (_, _) => DropdownButtonFormField<String>(
        key: ValueKey('subcategory-error-$categoryId'),
        initialValue: null,
        decoration: const InputDecoration(
          labelText: 'SubcategorÃƒÂ­a opcional',
          prefixIcon: Icon(Icons.folder_rounded),
        ),
        items: const [],
        onChanged: null,
      ),
    );
  }
}
