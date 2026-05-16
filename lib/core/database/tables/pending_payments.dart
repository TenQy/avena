import 'package:drift/drift.dart';

import 'sales.dart';
import 'users.dart';

class PendingPayments extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().nullable().references(Sales, #id)();
  TextColumn get customerName => text()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get description => text().nullable()();
  RealColumn get totalAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real()();
  TextColumn get status => text()();
  @ReferenceName('pendingPaymentCreatedByUser')
  TextColumn get createdByUserId => text().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
