import 'package:drift/drift.dart';

import 'users.dart';

class CashSessions extends Table {
  TextColumn get id => text()();
  @ReferenceName('cashSessionOpenedByUser')
  TextColumn get openedByUserId => text().references(Users, #id)();
  @ReferenceName('cashSessionClosedByUser')
  TextColumn get closedByUserId => text().nullable().references(Users, #id)();
  RealColumn get openingCashAmount => real()();
  RealColumn get expectedCashAmount => real()();
  RealColumn get closingCashAmount => real().nullable()();
  RealColumn get cashDifference => real().nullable()();
  RealColumn get cashIncome => real().withDefault(const Constant(0))();
  RealColumn get transferIncome => real().withDefault(const Constant(0))();
  RealColumn get terminalIncome => real().withDefault(const Constant(0))();
  RealColumn get bonusIncome => real().withDefault(const Constant(0))();
  RealColumn get commissionTotal => real().withDefault(const Constant(0))();
  TextColumn get status => text()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
