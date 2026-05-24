import 'package:drift/drift.dart';

import '../../constants/app_cash.dart';
import '../app_database.dart';
import '../tables/cash_movements.dart';
import '../tables/cash_sessions.dart';

part 'cash_dao.g.dart';

@DriftAccessor(tables: [CashSessions, CashMovements])
class CashDao extends DatabaseAccessor<AppDatabase> with _$CashDaoMixin {
  CashDao(super.db);

  Stream<List<CashSession>> watchCashSessions() {
    return select(cashSessions).watch();
  }

  Stream<CashSession?> watchOpenCashSession() {
    return (select(cashSessions)
          ..where(
            (session) => session.status.equals(AppCashSessionStatuses.open),
          )
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<CashSession?> getOpenCashSession() {
    return (select(cashSessions)
          ..where(
            (session) => session.status.equals(AppCashSessionStatuses.open),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<CashSession?> getCashSessionById(String id) {
    return (select(
      cashSessions,
    )..where((session) => session.id.equals(id))).getSingleOrNull();
  }

  Stream<List<CashMovement>> watchMovementsBySession(String cashSessionId) {
    return (select(cashMovements)
          ..where((movement) => movement.cashSessionId.equals(cashSessionId))
          ..orderBy([
            (movement) => OrderingTerm(
              expression: movement.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<void> insertCashSession(CashSessionsCompanion session) {
    return into(cashSessions).insert(session);
  }

  Future<bool> updateCashSession(CashSession session) async {
    return update(cashSessions).replace(session);
  }

  Future<void> insertCashMovement(CashMovementsCompanion movement) {
    return into(cashMovements).insert(movement);
  }
}
