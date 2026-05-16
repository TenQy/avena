// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_dao.dart';

// ignore_for_file: type=lint
mixin _$CashDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $CashSessionsTable get cashSessions => attachedDatabase.cashSessions;
  $CashMovementsTable get cashMovements => attachedDatabase.cashMovements;
  CashDaoManager get managers => CashDaoManager(this);
}

class CashDaoManager {
  final _$CashDaoMixin _db;
  CashDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$CashSessionsTableTableManager get cashSessions =>
      $$CashSessionsTableTableManager(_db.attachedDatabase, _db.cashSessions);
  $$CashMovementsTableTableManager get cashMovements =>
      $$CashMovementsTableTableManager(_db.attachedDatabase, _db.cashMovements);
}
