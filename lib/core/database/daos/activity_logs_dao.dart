import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/activity_logs.dart';

part 'activity_logs_dao.g.dart';

@DriftAccessor(tables: [ActivityLogs])
class ActivityLogsDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityLogsDaoMixin {
  ActivityLogsDao(super.db);

  Stream<List<ActivityLog>> watchActivityLogs() {
    return (select(activityLogs)
          ..orderBy([
            (table) => OrderingTerm.desc(table.createdAt),
            (table) => OrderingTerm.desc(table.id),
          ]))
        .watch();
  }

  Future<void> insertActivityLog(ActivityLogsCompanion log) {
    return into(activityLogs).insert(log);
  }
}
