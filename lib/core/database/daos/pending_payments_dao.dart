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
    return (select(
      pendingPayments,
    )..orderBy([(payment) => OrderingTerm.desc(payment.createdAt)])).watch();
  }

  Stream<List<PendingPaymentEntry>> watchEntriesByPendingPayment(
    String pendingPaymentId,
  ) {
    return (select(pendingPaymentEntries)
          ..where((entry) => entry.pendingPaymentId.equals(pendingPaymentId))
          ..orderBy([(entry) => OrderingTerm.desc(entry.createdAt)]))
        .watch();
  }

  Future<PendingPayment?> getPendingPaymentById(String id) {
    return (select(
      pendingPayments,
    )..where((payment) => payment.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertPendingPayment(PendingPaymentsCompanion pendingPayment) {
    return into(pendingPayments).insert(pendingPayment);
  }

  Future<void> insertPendingPaymentEntry(PendingPaymentEntriesCompanion entry) {
    return into(pendingPaymentEntries).insert(entry);
  }

  Future<bool> updatePendingPayment(PendingPayment payment) {
    return update(pendingPayments).replace(payment);
  }
}
