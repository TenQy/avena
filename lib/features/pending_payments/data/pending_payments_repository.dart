import 'package:drift/drift.dart';

import '../../../core/constants/app_pending_payments.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/constants/payment_methods.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';

enum PendingPaymentCreateResult {
  success,
  unauthorized,
  emptyCustomerName,
  invalidTotalAmount,
}

enum PendingPaymentEntryResult {
  success,
  unauthorized,
  paymentNotFound,
  alreadyCompleted,
  invalidAmount,
  exceedsRemainingAmount,
  invalidPaymentMethod,
}

class PendingPaymentsRepository {
  PendingPaymentsRepository(this._database);

  final AppDatabase _database;

  static const _pendingSync = 'pending';

  Stream<List<PendingPayment>> watchPendingPayments() {
    return _database.pendingPaymentsDao.watchPendingPayments();
  }

  Stream<List<PendingPaymentEntry>> watchEntriesByPendingPayment(
    String pendingPaymentId,
  ) {
    return _database.pendingPaymentsDao.watchEntriesByPendingPayment(
      pendingPaymentId,
    );
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

  Future<PendingPaymentEntryResult> createPaymentEntry({
    required User actor,
    required PendingPayment payment,
    required double amount,
    required String paymentMethod,
    String? note,
  }) async {
    if (!AppRoles.canAccessPendingPayments(actor.role)) {
      return PendingPaymentEntryResult.unauthorized;
    }

    final roundedAmount = double.parse(amount.toStringAsFixed(2));
    if (roundedAmount <= 0) {
      return PendingPaymentEntryResult.invalidAmount;
    }

    if (!AppPaymentMethods.mixable.contains(paymentMethod)) {
      return PendingPaymentEntryResult.invalidPaymentMethod;
    }

    final cleanNote = note?.trim();

    return _database.transaction(() async {
      final currentPayment = await _database.pendingPaymentsDao
          .getPendingPaymentById(payment.id);

      if (currentPayment == null) {
        return PendingPaymentEntryResult.paymentNotFound;
      }

      if (currentPayment.status == AppPendingPaymentStatuses.completed ||
          currentPayment.remainingAmount <= 0) {
        return PendingPaymentEntryResult.alreadyCompleted;
      }

      final roundedRemaining = double.parse(
        currentPayment.remainingAmount.toStringAsFixed(2),
      );
      if (roundedAmount > roundedRemaining) {
        return PendingPaymentEntryResult.exceedsRemainingAmount;
      }

      final paidAmount = double.parse(
        (currentPayment.paidAmount + roundedAmount).toStringAsFixed(2),
      );
      final remainingAmount = double.parse(
        (currentPayment.totalAmount - paidAmount).toStringAsFixed(2),
      );
      final isCompleted = remainingAmount <= 0;
      final chargedAmount = _chargedAmount(roundedAmount, paymentMethod);
      final now = DateTime.now();

      await _database.pendingPaymentsDao.insertPendingPaymentEntry(
        PendingPaymentEntriesCompanion.insert(
          id: IdGenerator.create(),
          pendingPaymentId: currentPayment.id,
          createdByUserId: actor.id,
          amount: roundedAmount,
          paymentMethod: paymentMethod,
          createdAt: now,
          note: Value(
            cleanNote == null || cleanNote.isEmpty ? null : cleanNote,
          ),
          syncStatus: _pendingSync,
        ),
      );

      await _database.pendingPaymentsDao.updatePendingPayment(
        currentPayment.copyWith(
          paidAmount: paidAmount,
          remainingAmount: isCompleted ? 0 : remainingAmount,
          status: isCompleted
              ? AppPendingPaymentStatuses.completed
              : AppPendingPaymentStatuses.partial,
          completedAt: isCompleted ? Value(now) : const Value.absent(),
          syncStatus: _pendingSync,
        ),
      );

      await _database.activityLogsDao.insertActivityLog(
        ActivityLogsCompanion.insert(
          id: IdGenerator.create(),
          userId: Value(actor.id),
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          action: AppPendingPaymentLogActions.createPaymentEntry,
          entityType: AppPendingPaymentLogEntities.pendingPayment,
          entityId: Value(currentPayment.id),
          description: Value(
            'Abono registrado para ${currentPayment.customerName} por '
            '\$${chargedAmount.toStringAsFixed(2)} '
            '(saldo cubierto: \$${roundedAmount.toStringAsFixed(2)})',
          ),
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      return PendingPaymentEntryResult.success;
    });
  }

  double _chargedAmount(double baseAmount, String paymentMethod) {
    return double.parse(
      (baseAmount * (1 + AppPaymentCommissions.rateFor(paymentMethod)))
          .toStringAsFixed(2),
    );
  }
}
