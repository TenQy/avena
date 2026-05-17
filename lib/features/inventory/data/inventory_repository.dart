import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';

enum CategorySaveResult { success, emptyName, nameTaken }

enum CategoryActionResult { success, hasProducts, notFound }

class InventoryRepository {
  InventoryRepository(this._database);

  final AppDatabase _database;

  static const _pendingSync = 'pending';

  Stream<List<Category>> watchCategories() {
    return _database.inventoryDao.watchVisibleCategories();
  }

  Future<CategorySaveResult> createCategory(String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return CategorySaveResult.emptyName;
    }

    final categories = await _database.inventoryDao
        .watchVisibleCategories()
        .first;
    final nameExists = categories.any(
      (category) => category.name.toLowerCase() == cleanName.toLowerCase(),
    );

    if (nameExists) {
      return CategorySaveResult.nameTaken;
    }

    final now = DateTime.now();
    final nextSortOrder = categories.isEmpty
        ? 0
        : categories
                  .map((category) => category.sortOrder)
                  .reduce(
                    (value, element) => value > element ? value : element,
                  ) +
              1;

    await _database.inventoryDao.insertCategory(
      CategoriesCompanion.insert(
        id: IdGenerator.create(),
        name: cleanName,
        sortOrder: Value(nextSortOrder),
        createdAt: now,
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return CategorySaveResult.success;
  }

  Future<CategoryActionResult> setMainCategory(
    Category selectedCategory,
  ) async {
    final categories = await _database.inventoryDao
        .watchVisibleCategories()
        .first;

    if (!categories.any((category) => category.id == selectedCategory.id)) {
      return CategoryActionResult.notFound;
    }

    final now = DateTime.now();
    final updatedCategories = <Category>[];

    updatedCategories.add(
      selectedCategory.copyWith(
        sortOrder: 0,
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    var nextSortOrder = 1;

    for (final category in categories) {
      if (category.id == selectedCategory.id) {
        continue;
      }

      updatedCategories.add(
        category.copyWith(
          sortOrder: nextSortOrder,
          updatedAt: now,
          syncStatus: _pendingSync,
        ),
      );
      nextSortOrder++;
    }

    await _database.inventoryDao.updateCategories(updatedCategories);

    return CategoryActionResult.success;
  }

  Future<CategoryActionResult> deleteCategory(Category category) async {
    final productCount = await _database.inventoryDao.countProductsByCategory(
      category.id,
    );

    if (productCount > 0) {
      return CategoryActionResult.hasProducts;
    }

    final now = DateTime.now();
    final updated = await _database.inventoryDao.updateCategory(
      category.copyWith(
        isActive: false,
        isDeleted: true,
        deletedAt: Value(now),
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    if (!updated) {
      return CategoryActionResult.notFound;
    }

    return CategoryActionResult.success;
  }
}
