// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$ActivityLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
  $ActivityLogsTable get activityLogs => attachedDatabase.activityLogs;
  ActivityLogsDaoManager get managers => ActivityLogsDaoManager(this);
}

class ActivityLogsDaoManager {
  final _$ActivityLogsDaoMixin _db;
  ActivityLogsDaoManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$ActivityLogsTableTableManager get activityLogs =>
      $$ActivityLogsTableTableManager(_db.attachedDatabase, _db.activityLogs);
}
