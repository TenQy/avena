import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/pending_payments_repository.dart';

final pendingPaymentsRepositoryProvider = Provider<PendingPaymentsRepository>((
  ref,
) {
  return PendingPaymentsRepository(ref.watch(databaseProvider));
});

final pendingPaymentsProvider = StreamProvider<List<PendingPayment>>((ref) {
  return ref.watch(pendingPaymentsRepositoryProvider).watchPendingPayments();
});
