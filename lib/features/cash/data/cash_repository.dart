import 'package:drift/drift.dart';

import '../../../core/constants/app_cash.dart';
import '../../../core/constants/app_activity_logs.dart';
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
      final sessionId = IdGenerator.create();

      await _database.cashDao.insertCashSession(
        CashSessionsCompanion.insert(
          id: sessionId,
          openedByUserId: actor.id,
          openingCashAmount: openingCashAmount,
          expectedCashAmount: openingCashAmount,
          status: AppCashSessionStatuses.open,
          openedAt: now,
          syncStatus: _pendingSync,
        ),
      );

      await _database.activityLogsDao.insertActivityLog(
        ActivityLogsCompanion.insert(
          id: IdGenerator.create(),
          userId: Value(actor.id),
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          action: AppActivityLogActions.openCash,
          entityType: AppActivityLogEntities.cashSession,
          entityId: Value(sessionId),
          description: Value(
            'Caja abierta con \$${openingCashAmount.toStringAsFixed(2)} iniciales',
          ),
          createdAt: now,
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

    final now = DateTime.now();
    final updated = await _database.cashDao.updateCashSession(
      currentOpenSession.copyWith(
        closedByUserId: Value(actor.id),
        status: AppCashSessionStatuses.closed,
        closedAt: Value(now),
        syncStatus: _pendingSync,
      ),
    );

    if (!updated) {
      return CloseCashResult.notFound;
    }

    await _database.activityLogsDao.insertActivityLog(
      ActivityLogsCompanion.insert(
        id: IdGenerator.create(),
        userId: Value(actor.id),
        userNameSnapshot: actor.username,
        userRoleSnapshot: actor.role,
        action: AppActivityLogActions.closeCash,
        entityType: AppActivityLogEntities.cashSession,
        entityId: Value(currentOpenSession.id),
        description: Value(
          'Caja cerrada con esperado de \$${currentOpenSession.expectedCashAmount.toStringAsFixed(2)}',
        ),
        createdAt: now,
        syncStatus: _pendingSync,
      ),
    );

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
      final movementId = IdGenerator.create();

      await _database.cashDao.insertCashMovement(
        CashMovementsCompanion.insert(
          id: movementId,
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

      await _database.activityLogsDao.insertActivityLog(
        ActivityLogsCompanion.insert(
          id: IdGenerator.create(),
          userId: Value(actor.id),
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          action: AppActivityLogActions.createCashMovement,
          entityType: AppActivityLogEntities.cashMovement,
          entityId: Value(movementId),
          description: Value(
            '${_movementLabel(type)} registrado por \$${amount.toStringAsFixed(2)}. '
            'Motivo: $cleanReason',
          ),
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      return CashMovementResult.success;
    });
  }

  String _movementLabel(CashMovementType type) {
    return type == CashMovementType.deposit ? 'Deposito' : 'Retiro';
  }
}
