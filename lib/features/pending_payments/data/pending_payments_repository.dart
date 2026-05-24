import 'package:drift/drift.dart';

import '../../../core/constants/app_pending_payments.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';

enum PendingPaymentCreateResult {
  success,
  unauthorized,
  emptyCustomerName,
  invalidTotalAmount,
}

class PendingPaymentsRepository {
  PendingPaymentsRepository(this._database);

  final AppDatabase _database;

  static const _pendingSync = 'pending';

  Stream<List<PendingPayment>> watchPendingPayments() {
    return _database.pendingPaymentsDao.watchPendingPayments();
  }

  Future<PendingPaymentCreateResult> createPendingPayment({
    required User actor,
    required String customerName,
    String? customerPhone,
    String? description,
    required double totalAmount,
  }) async {
    if (!AppRoles.canAccessPendingPayments(actor.role)) {
      return PendingPaymentCreateResult.unauthorized;
    }

    final cleanCustomerName = customerName.trim();
    if (cleanCustomerName.isEmpty) {
      return PendingPaymentCreateResult.emptyCustomerName;
    }

    if (totalAmount <= 0) {
      return PendingPaymentCreateResult.invalidTotalAmount;
    }

    final cleanPhone = customerPhone?.trim();
    final cleanDescription = description?.trim();
    final roundedTotal = double.parse(totalAmount.toStringAsFixed(2));
    final pendingPaymentId = IdGenerator.create();
    final now = DateTime.now();

    await _database.transaction(() async {
      await _database.pendingPaymentsDao.insertPendingPayment(
        PendingPaymentsCompanion.insert(
          id: pendingPaymentId,
          customerName: cleanCustomerName,
          customerPhone: Value(
            cleanPhone == null || cleanPhone.isEmpty ? null : cleanPhone,
          ),
          description: Value(
            cleanDescription == null || cleanDescription.isEmpty
                ? null
                : cleanDescription,
          ),
          totalAmount: roundedTotal,
          paidAmount: const Value(0),
          remainingAmount: roundedTotal,
          status: AppPendingPaymentStatuses.pending,
          createdByUserId: actor.id,
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      await _database.activityLogsDao.insertActivityLog(
        ActivityLogsCompanion.insert(
          id: IdGenerator.create(),
          userId: Value(actor.id),
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          action: AppPendingPaymentLogActions.createPendingPayment,
          entityType: AppPendingPaymentLogEntities.pendingPayment,
          entityId: Value(pendingPaymentId),
          description: Value(
            'Pago pendiente creado para $cleanCustomerName por '
            '\$${roundedTotal.toStringAsFixed(2)}',
          ),
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );
    });

    return PendingPaymentCreateResult.success;
  }
}
