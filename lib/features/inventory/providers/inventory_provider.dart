import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(databaseProvider));
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(inventoryRepositoryProvider).watchCategories();
});

final subcategoriesByCategoryProvider =
    StreamProvider.family<List<Subcategory>, String>((ref, categoryId) {
      return ref
          .watch(inventoryRepositoryProvider)
          .watchSubcategoriesByCategory(categoryId);
    });

final productsByCategoryProvider = StreamProvider.family<List<Product>, String>(
  (ref, categoryId) {
    return ref
        .watch(inventoryRepositoryProvider)
        .watchProductsByCategory(categoryId);
  },
);
