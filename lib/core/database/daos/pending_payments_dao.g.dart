// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_payments_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingPaymentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $CashSessionsTable get cashSessions => attachedDatabase.cashSessions;
  $SalesTable get sales => attachedDatabase.sales;
  $PendingPaymentsTable get pendingPayments => attachedDatabase.pendingPayments;
  $PendingPaymentEntriesTable get pendingPaymentEntries =>
      attachedDatabase.pendingPaymentEntries;
  PendingPaymentsDaoManager get managers => PendingPaymentsDaoManager(this);
}

class PendingPaymentsDaoManager {
  final _$PendingPaymentsDaoMixin _db;
  PendingPaymentsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$CashSessionsTableTableManager get cashSessions =>
      $$CashSessionsTableTableManager(_db.attachedDatabase, _db.cashSessions);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$PendingPaymentsTableTableManager get pendingPayments =>
      $$PendingPaymentsTableTableManager(
        _db.attachedDatabase,
        _db.pendingPayments,
      );
  $$PendingPaymentEntriesTableTableManager get pendingPaymentEntries =>
      $$PendingPaymentEntriesTableTableManager(
        _db.attachedDatabase,
        _db.pendingPaymentEntries,
      );
}
