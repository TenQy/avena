import 'package:drift/drift.dart';

import 'users.dart';

class ActivityLogs extends Table {
  TextColumn get id => text()();
  @ReferenceName('activityLogUser')
  TextColumn get userId => text().nullable().references(Users, #id)();
  TextColumn get userNameSnapshot => text()();
  TextColumn get userRoleSnapshot => text()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
