import 'package:drift/drift.dart';

import '../../../core/constants/app_products.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';

enum CategorySaveResult { success, emptyName, nameTaken }

enum SubcategorySaveResult { success, emptyName, nameTaken, categoryNotFound }

enum CategoryActionResult { success, hasProducts, notFound }

enum SubcategoryActionResult { success, notFound }

enum ProductActionResult { success, notFound }

enum ProductSaveResult {
  success,
  emptyName,
  missingCategory,
  invalidPrice,
  invalidStock,
  categoryNotFound,
  subcategoryNotFound,
}

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.categoryId,
    required this.productType,
    required this.price,
    required this.trackStock,
    this.brand,
    this.subcategoryId,
    this.description,
    this.stockQuantity,
  });

  final String name;
  final String? brand;
  final String categoryId;
  final String? subcategoryId;
  final String? description;
  final String productType;
  final double price;
  final bool trackStock;
  final double? stockQuantity;
}

class InventoryRepository {
  InventoryRepository(this._database);

  final AppDatabase _database;

  static const _pendingSync = 'pending';

  Stream<List<Category>> watchCategories() {
    return _database.inventoryDao.watchVisibleCategories();
  }

  Stream<List<Product>> watchProducts() {
    return _database.inventoryDao.watchProducts();
  }

  Stream<List<Subcategory>> watchSubcategoriesByCategory(String categoryId) {
    return _database.inventoryDao.watchSubcategoriesByCategory(categoryId);
  }

  Stream<List<Product>> watchProductsByCategory(String categoryId) {
    return _database.inventoryDao.watchVisibleProductsByCategory(categoryId);
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

  Future<SubcategorySaveResult> createSubcategory({
    required Category category,
    required String name,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return SubcategorySaveResult.emptyName;
    }

    final categories = await _database.inventoryDao
        .watchVisibleCategories()
        .first;
    final categoryExists = categories.any((item) => item.id == category.id);

    if (!categoryExists) {
      return SubcategorySaveResult.categoryNotFound;
    }

    final subcategories = await _database.inventoryDao
        .watchSubcategoriesByCategory(category.id)
        .first;
    final nameExists = subcategories.any(
      (subcategory) =>
          subcategory.name.toLowerCase() == cleanName.toLowerCase(),
    );

    if (nameExists) {
      return SubcategorySaveResult.nameTaken;
    }

    final now = DateTime.now();
    final nextSortOrder = subcategories.isEmpty
        ? 0
        : subcategories
                  .map((subcategory) => subcategory.sortOrder)
                  .reduce(
                    (value, element) => value > element ? value : element,
                  ) +
              1;

    await _database.inventoryDao.insertSubcategory(
      SubcategoriesCompanion.insert(
        id: IdGenerator.create(),
        categoryId: category.id,
        name: cleanName,
        sortOrder: Value(nextSortOrder),
        createdAt: now,
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return SubcategorySaveResult.success;
  }

  Future<ProductSaveResult> createProduct(ProductDraft draft) async {
    final validationResult = await _validateProductDraft(draft);
    if (validationResult != null) {
      return validationResult;
    }

    final cleanName = draft.name.trim();
    final cleanBrand = draft.brand?.trim();
    final cleanDescription = draft.description?.trim();
    final now = DateTime.now();
    final priceUnit = draft.productType == AppProductTypes.bulk
        ? AppProductPriceUnits.kilogram
        : AppProductPriceUnits.unit;

    await _database.inventoryDao.insertProduct(
      ProductsCompanion.insert(
        id: IdGenerator.create(),
        name: cleanName,
        brand: Value(
          cleanBrand == null || cleanBrand.isEmpty ? null : cleanBrand,
        ),
        categoryId: draft.categoryId,
        subcategoryId: Value(draft.subcategoryId),
        description: Value(
          cleanDescription == null || cleanDescription.isEmpty
              ? null
              : cleanDescription,
        ),
        productType: draft.productType,
        price: draft.price,
        priceUnit: priceUnit,
        trackStock: Value(draft.trackStock),
        stockQuantity: Value(draft.trackStock ? draft.stockQuantity : null),
        createdAt: now,
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return ProductSaveResult.success;
  }

  Future<ProductSaveResult> updateProduct(
    Product product,
    ProductDraft draft,
  ) async {
    final validationResult = await _validateProductDraft(draft);
    if (validationResult != null) {
      return validationResult;
    }

    final cleanName = draft.name.trim();
    final cleanBrand = draft.brand?.trim();
    final cleanDescription = draft.description?.trim();
    final now = DateTime.now();
    final priceUnit = draft.productType == AppProductTypes.bulk
        ? AppProductPriceUnits.kilogram
        : AppProductPriceUnits.unit;

    final updated = await _database.inventoryDao.updateProduct(
      product.copyWith(
        name: cleanName,
        brand: Value(
          cleanBrand == null || cleanBrand.isEmpty ? null : cleanBrand,
        ),
        categoryId: draft.categoryId,
        subcategoryId: Value(draft.subcategoryId),
        description: Value(
          cleanDescription == null || cleanDescription.isEmpty
              ? null
              : cleanDescription,
        ),
        productType: draft.productType,
        price: draft.price,
        priceUnit: priceUnit,
        trackStock: draft.trackStock,
        stockQuantity: Value(draft.trackStock ? draft.stockQuantity : null),
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    if (!updated) {
      return ProductSaveResult.categoryNotFound;
    }

    return ProductSaveResult.success;
  }

  Future<ProductActionResult> deleteProduct(Product product) async {
    final now = DateTime.now();
    final updated = await _database.inventoryDao.updateProduct(
      product.copyWith(
        isActive: false,
        isDeleted: true,
        deletedAt: Value(now),
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    if (!updated) {
      return ProductActionResult.notFound;
    }

    return ProductActionResult.success;
  }

  Future<ProductSaveResult?> _validateProductDraft(ProductDraft draft) async {
    final cleanName = draft.name.trim();

    if (cleanName.isEmpty) {
      return ProductSaveResult.emptyName;
    }

    if (draft.categoryId.trim().isEmpty) {
      return ProductSaveResult.missingCategory;
    }

    if (draft.price <= 0) {
      return ProductSaveResult.invalidPrice;
    }

    if (draft.trackStock &&
        (draft.stockQuantity == null || draft.stockQuantity! < 0)) {
      return ProductSaveResult.invalidStock;
    }

    final categories = await _database.inventoryDao
        .watchVisibleCategories()
        .first;
    final categoryExists = categories.any(
      (category) => category.id == draft.categoryId,
    );

    if (!categoryExists) {
      return ProductSaveResult.categoryNotFound;
    }

    if (draft.subcategoryId != null) {
      final subcategories = await _database.inventoryDao
          .watchSubcategoriesByCategory(draft.categoryId)
          .first;
      final subcategoryExists = subcategories.any(
        (subcategory) => subcategory.id == draft.subcategoryId,
      );

      if (!subcategoryExists) {
        return ProductSaveResult.subcategoryNotFound;
      }
    }

    return null;
  }

  Future<SubcategoryActionResult> deleteSubcategory(
    Subcategory subcategory,
  ) async {
    final now = DateTime.now();

    await _database.inventoryDao.clearProductsSubcategory(
      subcategoryId: subcategory.id,
      updatedAt: now,
      syncStatus: _pendingSync,
    );

    final updated = await _database.inventoryDao.updateSubcategory(
      subcategory.copyWith(
        isActive: false,
        isDeleted: true,
        deletedAt: Value(now),
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    if (!updated) {
      return SubcategoryActionResult.notFound;
    }

    return SubcategoryActionResult.success;
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
