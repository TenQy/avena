import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}
