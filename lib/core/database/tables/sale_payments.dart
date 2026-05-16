import 'package:drift/drift.dart';

import 'sales.dart';

class SalePayments extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get paymentMethod => text()();
  RealColumn get baseAmount => real()();
  RealColumn get commissionRate => real().withDefault(const Constant(0))();
  RealColumn get commissionAmount => real().withDefault(const Constant(0))();
  RealColumn get totalCharged => real()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
