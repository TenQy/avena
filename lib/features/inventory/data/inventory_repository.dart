import 'package:drift/drift.dart';

import '../../../core/constants/app_products.dart';
import '../../../core/constants/app_activity_logs.dart';
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
  invalidCost,
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
    this.cost,
    this.stockQuantity,
  });

  final String name;
  final String? brand;
  final String categoryId;
  final String? subcategoryId;
  final String? description;
  final String productType;
  final double price;
  final double? cost;
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

  Future<CategorySaveResult> createCategory({
    required User actor,
    required String name,
  }) async {
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
    final categoryId = IdGenerator.create();
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
        id: categoryId,
        name: cleanName,
        sortOrder: Value(nextSortOrder),
        createdAt: now,
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.createCategory,
        entityType: AppActivityLogEntities.category,
        entityId: Value(categoryId),
        description: Value('Categoria creada: $cleanName'),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return CategorySaveResult.success;
  }

  Future<SubcategorySaveResult> createSubcategory({
    required User actor,
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
    final subcategoryId = IdGenerator.create();
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
        id: subcategoryId,
        categoryId: category.id,
        name: cleanName,
        sortOrder: Value(nextSortOrder),
        createdAt: now,
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.createSubcategory,
        entityType: AppActivityLogEntities.subcategory,
        entityId: Value(subcategoryId),
        description: Value(
          'Subcategoria creada: $cleanName en ${category.name}',
        ),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return SubcategorySaveResult.success;
  }

  Future<ProductSaveResult> createProduct({
    required User actor,
    required ProductDraft draft,
  }) async {
    final validationResult = await _validateProductDraft(draft);
    if (validationResult != null) {
      return validationResult;
    }

    final cleanName = draft.name.trim();
    final cleanBrand = draft.brand?.trim();
    final cleanDescription = draft.description?.trim();
    final now = DateTime.now();
    final productId = IdGenerator.create();
    final priceUnit = draft.productType == AppProductTypes.bulk
        ? AppProductPriceUnits.kilogram
        : AppProductPriceUnits.unit;

    await _database.inventoryDao.insertProduct(
      ProductsCompanion.insert(
        id: productId,
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
        cost: Value(draft.cost),
        priceUnit: priceUnit,
        trackStock: Value(draft.trackStock),
        stockQuantity: Value(draft.trackStock ? draft.stockQuantity : null),
        createdAt: now,
        updatedAt: now,
        syncStatus: _pendingSync,
      ),
    );

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.createProduct,
        entityType: AppActivityLogEntities.product,
        entityId: Value(productId),
        description: Value(
          'Producto creado: $cleanName por \$${draft.price.toStringAsFixed(2)}',
        ),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return ProductSaveResult.success;
  }

  Future<ProductSaveResult> updateProduct(
    User actor,
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
        cost: Value(draft.cost),
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

    final priceChanged = product.price != draft.price;
    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.updateProduct,
        entityType: AppActivityLogEntities.product,
        entityId: Value(product.id),
        description: Value(
          'Producto actualizado: $cleanName'
          '${priceChanged ? ' | nuevo precio \$${draft.price.toStringAsFixed(2)}' : ''}',
        ),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return ProductSaveResult.success;
  }

  Future<ProductActionResult> deleteProduct({
    required User actor,
    required Product product,
  }) async {
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

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.deleteProduct,
        entityType: AppActivityLogEntities.product,
        entityId: Value(product.id),
        description: Value('Producto eliminado: ${product.name}'),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

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

    if (draft.cost != null && draft.cost! < 0) {
      return ProductSaveResult.invalidCost;
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
    User actor,
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

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.deleteSubcategory,
        entityType: AppActivityLogEntities.subcategory,
        entityId: Value(subcategory.id),
        description: Value(
          'Subcategoria eliminada: ${subcategory.name}',
        ),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return SubcategoryActionResult.success;
  }

  Future<CategoryActionResult> setMainCategory(
    User actor,
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

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.setMainCategory,
        entityType: AppActivityLogEntities.category,
        entityId: Value(selectedCategory.id),
        description: Value(
          'Categoria principal actualizada: ${selectedCategory.name}',
        ),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return CategoryActionResult.success;
  }

  Future<CategoryActionResult> deleteCategory({
    required User actor,
    required Category category,
  }) async {
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

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.deleteCategory,
        entityType: AppActivityLogEntities.category,
        entityId: Value(category.id),
        description: Value('Categoria eliminada: ${category.name}'),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

    return CategoryActionResult.success;
  }
}
