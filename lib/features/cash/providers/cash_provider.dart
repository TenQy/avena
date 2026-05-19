import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/cash_repository.dart';

final cashRepositoryProvider = Provider<CashRepository>((ref) {
  return CashRepository(ref.watch(databaseProvider));
});

final currentCashSessionProvider = StreamProvider<CashSession?>((ref) {
  return ref.watch(cashRepositoryProvider).watchOpenCashSession();
});

final cashMovementsBySessionProvider =
    StreamProvider.family<List<CashMovement>, String>((ref, cashSessionId) {
      return ref
          .watch(cashRepositoryProvider)
          .watchMovementsBySession(cashSessionId);
    });
