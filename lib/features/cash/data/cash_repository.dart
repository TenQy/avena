import 'package:drift/drift.dart';

import '../../../core/constants/app_cash.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';

enum OpenCashResult { success, unauthorized, invalidOpeningAmount, alreadyOpen }

enum CloseCashResult { success, unauthorized, notFound }

enum CashMovementResult {
  success,
  unauthorized,
  invalidAmount,
  emptyReason,
  sessionNotFound,
}

enum CashMovementType {
  withdrawal(AppCashMovementTypes.withdrawal),
  deposit(AppCashMovementTypes.deposit);

  const CashMovementType(this.value);

  final String value;
}

class CashRepository {
  CashRepository(this._database);

  final AppDatabase _database;

  static const _pendingSync = 'pending';

  Stream<CashSession?> watchOpenCashSession() {
    return _database.cashDao.watchOpenCashSession();
  }

  Stream<List<CashMovement>> watchMovementsBySession(String cashSessionId) {
    return _database.cashDao.watchMovementsBySession(cashSessionId);
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
          status: AppCashSessionStatuses.open,
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
        status: AppCashSessionStatuses.closed,
        closedAt: Value(DateTime.now()),
        syncStatus: _pendingSync,
      ),
    );

    if (!updated) {
      return CloseCashResult.notFound;
    }

    return CloseCashResult.success;
  }

  Future<CashMovementResult> createMovement({
    required User actor,
    required CashSession session,
    required CashMovementType type,
    required double amount,
    required String reason,
  }) async {
    if (!AppRoles.canManageCash(actor.role)) {
      return CashMovementResult.unauthorized;
    }

    if (amount <= 0) {
      return CashMovementResult.invalidAmount;
    }

    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      return CashMovementResult.emptyReason;
    }

    return _database.transaction(() async {
      final currentOpenSession = await _database.cashDao.getOpenCashSession();

      if (currentOpenSession == null || currentOpenSession.id != session.id) {
        return CashMovementResult.sessionNotFound;
      }

      final signedAmount = type == CashMovementType.deposit ? amount : -amount;
      final now = DateTime.now();

      await _database.cashDao.insertCashMovement(
        CashMovementsCompanion.insert(
          id: IdGenerator.create(),
          cashSessionId: currentOpenSession.id,
          createdByUserId: actor.id,
          type: type.value,
          amount: amount,
          reason: cleanReason,
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      final updated = await _database.cashDao.updateCashSession(
        currentOpenSession.copyWith(
          expectedCashAmount:
              currentOpenSession.expectedCashAmount + signedAmount,
          syncStatus: _pendingSync,
        ),
      );

      if (!updated) {
        return CashMovementResult.sessionNotFound;
      }

      return CashMovementResult.success;
    });
  }
}
