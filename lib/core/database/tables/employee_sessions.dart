import 'package:drift/drift.dart';

import 'users.dart';

class EmployeeSessions extends Table {
  TextColumn get id => text()();
  @ReferenceName('employeeSessionUser')
  TextColumn get userId => text().references(Users, #id)();
  @ReferenceName('employeeSessionStartedByAdmin')
  TextColumn get startedByAdminId => text().references(Users, #id)();
  @ReferenceName('employeeSessionEndedByAdmin')
  TextColumn get endedByAdminId => text().nullable().references(Users, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
