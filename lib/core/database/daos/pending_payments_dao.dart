import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/pending_payment_entries.dart';
import '../tables/pending_payments.dart';

part 'pending_payments_dao.g.dart';

@DriftAccessor(tables: [PendingPayments, PendingPaymentEntries])
class PendingPaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PendingPaymentsDaoMixin {
  PendingPaymentsDao(super.db);

  Stream<List<PendingPayment>> watchPendingPayments() {
    return select(pendingPayments).watch();
  }

  Stream<List<PendingPaymentEntry>> watchEntriesByPendingPayment(
    String pendingPaymentId,
  ) {
    return (select(pendingPaymentEntries)
          ..where((entry) => entry.pendingPaymentId.equals(pendingPaymentId)))
        .watch();
  }

  Future<void> insertPendingPayment(PendingPaymentsCompanion pendingPayment) {
    return into(pendingPayments).insert(pendingPayment);
  }

  Future<void> insertPendingPaymentEntry(PendingPaymentEntriesCompanion entry) {
    return into(pendingPaymentEntries).insert(entry);
  }
}
