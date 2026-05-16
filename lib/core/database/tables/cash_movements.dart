import 'package:drift/drift.dart';

import 'cash_sessions.dart';
import 'users.dart';

class CashMovements extends Table {
  TextColumn get id => text()();
  TextColumn get cashSessionId => text().references(CashSessions, #id)();
  @ReferenceName('cashMovementCreatedByUser')
  TextColumn get createdByUserId => text().references(Users, #id)();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get reason => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
