import '../../../core/database/app_database.dart';

class LogsRepository {
  LogsRepository(this._database);

  final AppDatabase _database;

  Stream<List<ActivityLog>> watchActivityLogs() {
    return _database.activityLogsDao.watchActivityLogs();
  }
}
