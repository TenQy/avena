import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_queue.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Stream<List<SyncQueueData>> watchPendingOperations() {
    return (select(
      syncQueue,
    )..where((operation) => operation.status.equals('pending'))).watch();
  }

  Future<void> insertSyncOperation(SyncQueueCompanion operation) {
    return into(syncQueue).insert(operation);
  }
}
