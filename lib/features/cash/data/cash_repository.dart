import 'package:drift/drift.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';

enum OpenCashResult { success, unauthorized, invalidOpeningAmount, alreadyOpen }

enum CloseCashResult { success, unauthorized, notFound }

class CashRepository {
  CashRepository(this._database);

  final AppDatabase _database;

  static const _openStatus = 'open';
  static const _closedStatus = 'closed';
  static const _pendingSync = 'pending';

  Stream<CashSession?> watchOpenCashSession() {
    return _database.cashDao.watchOpenCashSession();
  }

  Future<OpenCashResult> openCashSession({
    required User actor,
    required double openingCashAmount,
  }) async {
    if (!AppRoles.canManageCash(actor.role)) {
      return OpenCashResult.unauthorized;
    }

    if (openingCashAmount < 0) {
      return OpenCashResult.invalidOpeningAmount;
    }

    return _database.transaction(() async {
      final currentOpenSession = await _database.cashDao.getOpenCashSession();

      if (currentOpenSession != null) {
        return OpenCashResult.alreadyOpen;
      }

      final now = DateTime.now();

      await _database.cashDao.insertCashSession(
        CashSessionsCompanion.insert(
          id: IdGenerator.create(),
          openedByUserId: actor.id,
          openingCashAmount: openingCashAmount,
          expectedCashAmount: openingCashAmount,
          status: _openStatus,
          openedAt: now,
          syncStatus: _pendingSync,
        ),
      );

      return OpenCashResult.success;
    });
  }

  Future<CloseCashResult> closeCashSession({
    required User actor,
    required CashSession session,
  }) async {
    if (!AppRoles.canManageCash(actor.role)) {
      return CloseCashResult.unauthorized;
    }

    final currentOpenSession = await _database.cashDao.getOpenCashSession();

    if (currentOpenSession == null || currentOpenSession.id != session.id) {
      return CloseCashResult.notFound;
    }

    final updated = await _database.cashDao.updateCashSession(
      currentOpenSession.copyWith(
        closedByUserId: Value(actor.id),
        status: _closedStatus,
        closedAt: Value(DateTime.now()),
        syncStatus: _pendingSync,
      ),
    );

    if (!updated) {
      return CloseCashResult.notFound;
    }

    return CloseCashResult.success;
  }
}
