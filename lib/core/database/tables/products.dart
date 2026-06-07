import 'package:drift/drift.dart';

import 'categories.dart';
import 'subcategories.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get subcategoryId =>
      text().nullable().references(Subcategories, #id)();
  TextColumn get description => text().nullable()();
  TextColumn get productType => text()();
  RealColumn get price => real()();
  RealColumn get cost => real().nullable()();
  TextColumn get priceUnit => text()();
  BoolColumn get trackStock => boolean().withDefault(const Constant(false))();
  RealColumn get stockQuantity => real().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
