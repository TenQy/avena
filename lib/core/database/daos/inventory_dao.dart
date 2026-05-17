import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories.dart';
import '../tables/products.dart';
import '../tables/subcategories.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Categories, Subcategories, Products])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  Stream<List<Category>> watchCategories() => select(categories).watch();

  Stream<List<Category>> watchVisibleCategories() {
    return (select(categories)
          ..where((category) => category.isDeleted.equals(false))
          ..orderBy([
            (category) => OrderingTerm(expression: category.sortOrder),
            (category) => OrderingTerm(expression: category.name),
          ]))
        .watch();
  }

  Future<int> countProductsByCategory(String categoryId) {
    final productCount = products.id.count();

    return (selectOnly(products)
          ..addColumns([productCount])
          ..where(
            products.categoryId.equals(categoryId) &
                products.isDeleted.equals(false),
          ))
        .map((row) => row.read(productCount) ?? 0)
        .getSingle();
  }

  Future<bool> updateCategory(Insertable<Category> category) {
    return update(categories).replace(category);
  }

  Future<void> updateCategories(
    List<Insertable<Category>> categoryItems,
  ) async {
    await batch((batch) {
      batch.replaceAll(categories, categoryItems);
    });
  }

  Stream<List<Subcategory>> watchSubcategoriesByCategory(String categoryId) {
    return (select(subcategories)
          ..where((subcategory) => subcategory.categoryId.equals(categoryId)))
        .watch();
  }

  Stream<List<Product>> watchProducts() => select(products).watch();

  Future<void> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<void> insertSubcategory(SubcategoriesCompanion subcategory) {
    return into(subcategories).insert(subcategory);
  }

  Future<void> insertProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }
}
