import 'package:drift/drift.dart';

import 'categories.dart';

class Subcategories extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
