import 'package:drift/drift.dart';

import 'products.dart';
import 'sales.dart';

class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get productNameSnapshot => text()();
  TextColumn get productBrandSnapshot => text().nullable()();
  TextColumn get productTypeSnapshot => text()();
  TextColumn get priceUnitSnapshot => text()();
  RealColumn get unitPriceSnapshot => real()();
  RealColumn get quantity => real()();
  TextColumn get quantityUnit => text()();
  RealColumn get subtotal => real()();

  @override
  Set<Column> get primaryKey => {id};
}
