import 'package:drift/drift.dart';

import 'cash_sessions.dart';
import 'users.dart';

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get cashSessionId => text().references(CashSessions, #id)();
  @ReferenceName('saleUser')
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get userNameSnapshot => text()();
  TextColumn get userRoleSnapshot => text()();
  RealColumn get subtotal => real()();
  RealColumn get commissionTotal => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get pendingAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentStatus => text()();
  TextColumn get saleStatus => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  @ReferenceName('saleCancelledByUser')
  TextColumn get cancelledByUserId =>
      text().nullable().references(Users, #id)();
  TextColumn get cancelReason => text().nullable()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
