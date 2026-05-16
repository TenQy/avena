import 'package:drift/drift.dart';

import 'pending_payments.dart';
import 'users.dart';

class PendingPaymentEntries extends Table {
  TextColumn get id => text()();
  TextColumn get pendingPaymentId => text().references(PendingPayments, #id)();
  @ReferenceName('pendingPaymentEntryCreatedByUser')
  TextColumn get createdByUserId => text().references(Users, #id)();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
