import 'package:drift/drift.dart';

import '../../../core/constants/app_activity_logs.dart';
import '../../../core/constants/app_pending_payments.dart';
import '../../../core/constants/app_products.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/constants/app_sales.dart';
import '../../../core/constants/payment_methods.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/id_generator.dart';

enum SaleRegisterResult {
  success,
  unauthorized,
  emptySale,
  emptyCustomerName,
  invalidPayment,
  invalidPendingAmount,
  cashSessionNotFound,
  productNotFound,
  insufficientStock,
}

enum SaleCancelResult {
  success,
  unauthorized,
  emptyReason,
  notFound,
  alreadyCancelled,
  cashSessionNotFound,
}

class SaleRegisterItem {
  const SaleRegisterItem({
    required this.product,
    required this.quantity,
    required this.subtotal,
  });

  final Product product;
  final double quantity;
  final double subtotal;
}

class SaleRegisterDraft {
  const SaleRegisterDraft({
    required this.items,
    required this.paymentMethod,
    required this.mixedPayments,
  });

  final List<SaleRegisterItem> items;
  final String paymentMethod;
  final Map<String, double> mixedPayments;
}

class PendingSaleInput {
  const PendingSaleInput({
    required this.customerName,
    this.customerPhone,
    this.description,
    required this.initialPaidAmount,
    required this.initialPaymentMethod,
  });

  final String customerName;
  final String? customerPhone;
  final String? description;
  final double initialPaidAmount;
  final String initialPaymentMethod;
}

class SalesRepository {
  SalesRepository(this._database);

  final AppDatabase _database;

  static const _pendingSync = 'pending';
  static const _centTolerance = 0.01;

  Stream<List<Sale>> watchSalesBetween(DateTime start, DateTime end) {
    return _database.salesDao.watchSalesBetween(start, end);
  }

  Stream<List<Sale>> watchSalesBetweenByPayment(
    DateTime start,
    DateTime end,
    String paymentMethod,
  ) {
    return _database.salesDao.watchSalesBetweenByPayment(
      start,
      end,
      paymentMethod,
    );
  }

  Stream<List<SaleItem>> watchItemsBySale(String saleId) {
    return _database.salesDao.watchItemsBySale(saleId);
  }

  Stream<List<SalePayment>> watchPaymentsBySale(String saleId) {
    return _database.salesDao.watchPaymentsBySale(saleId);
  }

  Future<SaleCancelResult> cancelSale({
    required User actor,
    required Sale sale,
    required String reason,
  }) async {
    if (!AppRoles.canCancelSales(actor.role)) {
      return SaleCancelResult.unauthorized;
    }

    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      return SaleCancelResult.emptyReason;
    }

    return _database.transaction(() async {
      final currentSale = await _database.salesDao.getSaleById(sale.id);
      if (currentSale == null) {
        return SaleCancelResult.notFound;
      }

      if (currentSale.saleStatus == AppSaleStatuses.cancelled) {
        return SaleCancelResult.alreadyCancelled;
      }

      final cashSession = await _database.cashDao.getCashSessionById(
        currentSale.cashSessionId,
      );
      if (cashSession == null) {
        return SaleCancelResult.cashSessionNotFound;
      }

      final items = await _database.salesDao.getItemsBySale(currentSale.id);
      final payments = await _database.salesDao.getPaymentsBySale(
        currentSale.id,
      );
      final now = DateTime.now();

      await _database.cashDao.updateCashSession(
        _reversePaymentsFromCashSession(
          session: cashSession,
          payments: payments,
          commissionTotal: currentSale.commissionTotal,
        ),
      );

      for (final item in items) {
        final product = await _database.inventoryDao.getProductById(
          item.productId,
        );
        if (product == null || !product.trackStock) {
          continue;
        }

        await _database.inventoryDao.updateProduct(
          product.copyWith(
            stockQuantity: Value(
              _roundQuantity((product.stockQuantity ?? 0) + item.quantity),
            ),
            updatedAt: now,
            syncStatus: _pendingSync,
          ),
        );
      }

      await _database.salesDao.updateSale(
        currentSale.copyWith(
          saleStatus: AppSaleStatuses.cancelled,
          cancelledAt: Value(now),
          cancelledByUserId: Value(actor.id),
          cancelReason: Value(cleanReason),
          syncStatus: _pendingSync,
        ),
      );

      await _database.activityLogsDao.insertActivityLog(
        ActivityLogsCompanion.insert(
          id: IdGenerator.create(),
          userId: Value(actor.id),
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          action: AppActivityLogActions.cancelSale,
          entityType: AppActivityLogEntities.sale,
          entityId: Value(currentSale.id),
          description: Value(
            'Venta cancelada por \$${currentSale.total.toStringAsFixed(2)}. '
            'Motivo: $cleanReason',
          ),
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      return SaleCancelResult.success;
    });
  }

  Future<SaleRegisterResult> registerSale({
    required User actor,
    required SaleRegisterDraft draft,
  }) async {
    if (!AppRoles.canAccessSales(actor.role)) {
      return SaleRegisterResult.unauthorized;
    }

    if (draft.items.isEmpty) {
      return SaleRegisterResult.emptySale;
    }

    if (!_isValidPaymentDraft(draft)) {
      return SaleRegisterResult.invalidPayment;
    }

    return _database.transaction(() async {
      final cashSession = await _database.cashDao.getOpenCashSession();
      if (cashSession == null) {
        return SaleRegisterResult.cashSessionNotFound;
      }

      final now = DateTime.now();
      final saleId = IdGenerator.create();
      final subtotal = _roundMoney(
        draft.items.fold(0.0, (total, item) => total + item.subtotal),
      );
      final payments = _buildPayments(draft, subtotal);
      final commissionTotal = _roundMoney(
        payments.fold(
          0.0,
          (total, payment) => total + payment.commissionAmount,
        ),
      );
      final total = _roundMoney(
        payments.fold(0.0, (sum, payment) => sum + payment.totalCharged),
      );
      final currentProducts = <String, Product>{};

      for (final item in draft.items) {
        final currentProduct = await _database.inventoryDao.getProductById(
          item.product.id,
        );

        if (currentProduct == null || currentProduct.isDeleted) {
          return SaleRegisterResult.productNotFound;
        }

        if (currentProduct.trackStock) {
          final currentStock = currentProduct.stockQuantity ?? 0;
          if (currentStock + _centTolerance < item.quantity) {
            return SaleRegisterResult.insufficientStock;
          }
        }

        currentProducts[item.product.id] = currentProduct;
      }

      final updatedSession = _applyPaymentsToCashSession(
        session: cashSession,
        payments: payments,
        commissionTotal: commissionTotal,
      );
      final cashUpdated = await _database.cashDao.updateCashSession(
        updatedSession,
      );

      if (!cashUpdated) {
        return SaleRegisterResult.cashSessionNotFound;
      }

      for (final item in draft.items) {
        final currentProduct = currentProducts[item.product.id]!;
        if (!currentProduct.trackStock) {
          continue;
        }

        await _database.inventoryDao.updateProduct(
          currentProduct.copyWith(
            stockQuantity: Value(
              _roundQuantity(
                (currentProduct.stockQuantity ?? 0) - item.quantity,
              ),
            ),
            updatedAt: now,
            syncStatus: _pendingSync,
          ),
        );
      }

      await _database.salesDao.insertSale(
        SalesCompanion.insert(
          id: saleId,
          cashSessionId: cashSession.id,
          userId: actor.id,
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          subtotal: subtotal,
          commissionTotal: Value(commissionTotal),
          total: total,
          paidAmount: Value(total),
          pendingAmount: const Value(0),
          paymentStatus: AppPaymentStatuses.paid,
          saleStatus: AppSaleStatuses.completed,
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      for (final item in draft.items) {
        final product = item.product;

        await _database.salesDao.insertSaleItem(
          SaleItemsCompanion.insert(
            id: IdGenerator.create(),
            saleId: saleId,
            productId: product.id,
            productNameSnapshot: product.name,
            productBrandSnapshot: Value(product.brand),
            productTypeSnapshot: product.productType,
            priceUnitSnapshot: product.priceUnit,
            unitPriceSnapshot: product.price,
            quantity: item.quantity,
            quantityUnit: product.productType == AppProductTypes.bulk
                ? AppProductPriceUnits.kilogram
                : AppProductPriceUnits.unit,
            subtotal: item.subtotal,
          ),
        );
      }

      for (final payment in payments) {
        await _database.salesDao.insertSalePayment(
          SalePaymentsCompanion.insert(
            id: IdGenerator.create(),
            saleId: saleId,
            paymentMethod: payment.method,
            baseAmount: payment.baseAmount,
            commissionRate: Value(payment.commissionRate),
            commissionAmount: Value(payment.commissionAmount),
            totalCharged: payment.totalCharged,
            createdAt: now,
            syncStatus: _pendingSync,
          ),
        );
      }

      await _database.activityLogsDao.insertActivityLog(
        ActivityLogsCompanion.insert(
          id: IdGenerator.create(),
          userId: Value(actor.id),
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          action: AppActivityLogActions.createSale,
          entityType: AppActivityLogEntities.sale,
          entityId: Value(saleId),
          description: Value(
            'Venta registrada por \$${total.toStringAsFixed(2)}',
          ),
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      return SaleRegisterResult.success;
    });
  }

  Future<SaleRegisterResult> registerPendingSale({
    required User actor,
    required SaleRegisterDraft draft,
    required PendingSaleInput pendingInput,
  }) async {
    if (!AppRoles.canAccessSales(actor.role)) {
      return SaleRegisterResult.unauthorized;
    }

    if (draft.items.isEmpty) {
      return SaleRegisterResult.emptySale;
    }

    final customerName = pendingInput.customerName.trim();
    if (customerName.isEmpty) {
      return SaleRegisterResult.emptyCustomerName;
    }

    final subtotal = _roundMoney(
      draft.items.fold(0.0, (total, item) => total + item.subtotal),
    );
    final initialPaidAmount = _roundMoney(pendingInput.initialPaidAmount);
    if (initialPaidAmount < 0 ||
        initialPaidAmount >= subtotal ||
        (initialPaidAmount > 0 &&
            !AppPaymentMethods.mixable.contains(
              pendingInput.initialPaymentMethod,
            ))) {
      return SaleRegisterResult.invalidPendingAmount;
    }

    return _database.transaction(() async {
      final cashSession = await _database.cashDao.getOpenCashSession();
      if (cashSession == null) {
        return SaleRegisterResult.cashSessionNotFound;
      }

      final now = DateTime.now();
      final saleId = IdGenerator.create();
      final pendingPaymentId = IdGenerator.create();
      final currentProducts = <String, Product>{};
      final initialPayments = initialPaidAmount > 0
          ? [
              _SalePaymentDraft.fromBase(
                pendingInput.initialPaymentMethod,
                initialPaidAmount,
              ),
            ]
          : <_SalePaymentDraft>[];
      final commissionTotal = initialPayments.fold(
        0.0,
        (total, payment) => total + payment.commissionAmount,
      );
      final paidCharge = initialPayments.fold(
        0.0,
        (total, payment) => total + payment.totalCharged,
      );
      final pendingAmount = _roundMoney(subtotal - initialPaidAmount);

      for (final item in draft.items) {
        final currentProduct = await _database.inventoryDao.getProductById(
          item.product.id,
        );

        if (currentProduct == null || currentProduct.isDeleted) {
          return SaleRegisterResult.productNotFound;
        }

        if (currentProduct.trackStock &&
            (currentProduct.stockQuantity ?? 0) + _centTolerance <
                item.quantity) {
          return SaleRegisterResult.insufficientStock;
        }

        currentProducts[item.product.id] = currentProduct;
      }

      final cashUpdated = await _database.cashDao.updateCashSession(
        _applyPaymentsToCashSession(
          session: cashSession,
          payments: initialPayments,
          commissionTotal: commissionTotal,
        ),
      );
      if (!cashUpdated) {
        return SaleRegisterResult.cashSessionNotFound;
      }

      for (final item in draft.items) {
        final currentProduct = currentProducts[item.product.id]!;
        if (!currentProduct.trackStock) {
          continue;
        }

        await _database.inventoryDao.updateProduct(
          currentProduct.copyWith(
            stockQuantity: Value(
              _roundQuantity(
                (currentProduct.stockQuantity ?? 0) - item.quantity,
              ),
            ),
            updatedAt: now,
            syncStatus: _pendingSync,
          ),
        );
      }

      await _database.salesDao.insertSale(
        SalesCompanion.insert(
          id: saleId,
          cashSessionId: cashSession.id,
          userId: actor.id,
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          subtotal: subtotal,
          commissionTotal: Value(_roundMoney(commissionTotal)),
          total: _roundMoney(subtotal + commissionTotal),
          paidAmount: Value(_roundMoney(paidCharge)),
          pendingAmount: Value(pendingAmount),
          paymentStatus: initialPaidAmount > 0
              ? AppPaymentStatuses.partial
              : AppPaymentStatuses.pending,
          saleStatus: AppSaleStatuses.completed,
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      for (final item in draft.items) {
        final product = item.product;
        await _database.salesDao.insertSaleItem(
          SaleItemsCompanion.insert(
            id: IdGenerator.create(),
            saleId: saleId,
            productId: product.id,
            productNameSnapshot: product.name,
            productBrandSnapshot: Value(product.brand),
            productTypeSnapshot: product.productType,
            priceUnitSnapshot: product.priceUnit,
            unitPriceSnapshot: product.price,
            quantity: item.quantity,
            quantityUnit: product.productType == AppProductTypes.bulk
                ? AppProductPriceUnits.kilogram
                : AppProductPriceUnits.unit,
            subtotal: item.subtotal,
          ),
        );
      }

      for (final payment in initialPayments) {
        await _database.salesDao.insertSalePayment(
          SalePaymentsCompanion.insert(
            id: IdGenerator.create(),
            saleId: saleId,
            paymentMethod: payment.method,
            baseAmount: payment.baseAmount,
            commissionRate: Value(payment.commissionRate),
            commissionAmount: Value(payment.commissionAmount),
            totalCharged: payment.totalCharged,
            createdAt: now,
            syncStatus: _pendingSync,
          ),
        );
      }

      final customerPhone = pendingInput.customerPhone?.trim();
      await _database.pendingPaymentsDao.insertPendingPayment(
        PendingPaymentsCompanion.insert(
          id: pendingPaymentId,
          saleId: Value(saleId),
          customerName: customerName,
          customerPhone: Value(
            customerPhone == null || customerPhone.isEmpty
                ? null
                : customerPhone,
          ),
          description: Value(_pendingSaleDescription(draft, pendingInput)),
          totalAmount: subtotal,
          paidAmount: Value(initialPaidAmount),
          remainingAmount: pendingAmount,
          status: initialPaidAmount > 0
              ? AppPendingPaymentStatuses.partial
              : AppPendingPaymentStatuses.pending,
          createdByUserId: actor.id,
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      if (initialPaidAmount > 0) {
        await _database.pendingPaymentsDao.insertPendingPaymentEntry(
          PendingPaymentEntriesCompanion.insert(
            id: IdGenerator.create(),
            pendingPaymentId: pendingPaymentId,
            createdByUserId: actor.id,
            amount: initialPaidAmount,
            paymentMethod: pendingInput.initialPaymentMethod,
            createdAt: now,
            note: const Value('Abono al registrar la venta'),
            syncStatus: _pendingSync,
          ),
        );

        await _database.activityLogsDao.insertActivityLog(
          ActivityLogsCompanion.insert(
            id: IdGenerator.create(),
            userId: Value(actor.id),
            userNameSnapshot: actor.username,
            userRoleSnapshot: actor.role,
            action: AppActivityLogActions.createPaymentEntry,
            entityType: AppActivityLogEntities.pendingPayment,
            entityId: Value(pendingPaymentId),
            description: Value(
              'Abono inicial para $customerName por '
              '\$${paidCharge.toStringAsFixed(2)} '
              '(saldo cubierto: \$${initialPaidAmount.toStringAsFixed(2)})',
            ),
            createdAt: now,
            syncStatus: _pendingSync,
          ),
        );
      }

      await _database.activityLogsDao.insertActivityLog(
        ActivityLogsCompanion.insert(
          id: IdGenerator.create(),
          userId: Value(actor.id),
          userNameSnapshot: actor.username,
          userRoleSnapshot: actor.role,
          action: AppActivityLogActions.createSale,
          entityType: AppActivityLogEntities.sale,
          entityId: Value(saleId),
          description: Value(
            'Venta con pago pendiente registrada por '
            '\$${subtotal.toStringAsFixed(2)}',
          ),
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
          action: AppActivityLogActions.createPendingPayment,
          entityType: AppActivityLogEntities.pendingPayment,
          entityId: Value(pendingPaymentId),
          description: Value(
            'Pago pendiente creado desde venta para $customerName por '
            '\$${pendingAmount.toStringAsFixed(2)}',
          ),
          createdAt: now,
          syncStatus: _pendingSync,
        ),
      );

      return SaleRegisterResult.success;
    });
  }

  String _pendingSaleDescription(
    SaleRegisterDraft draft,
    PendingSaleInput pendingInput,
  ) {
    final customDescription = pendingInput.description?.trim();
    final products = draft.items
        .map((item) => '${item.product.name} x${item.quantity}')
        .join(', ');

    if (customDescription == null || customDescription.isEmpty) {
      return 'Productos: $products';
    }

    return '$customDescription\nProductos: $products';
  }

  bool _isValidPaymentDraft(SaleRegisterDraft draft) {
    if (!AppPaymentMethods.all.contains(draft.paymentMethod)) {
      return false;
    }

    if (draft.paymentMethod != AppPaymentMethods.mixed) {
      return true;
    }

    if (draft.mixedPayments.isEmpty) {
      return false;
    }

    if (draft.mixedPayments.keys.any(
      (method) => !AppPaymentMethods.mixable.contains(method),
    )) {
      return false;
    }

    final subtotal = draft.items.fold(
      0.0,
      (total, item) => total + item.subtotal,
    );
    final mixedBaseTotal = draft.mixedPayments.values.fold(
      0.0,
      (total, amount) => total + amount,
    );

    return (mixedBaseTotal - subtotal).abs() <= _centTolerance;
  }

  List<_SalePaymentDraft> _buildPayments(
    SaleRegisterDraft draft,
    double subtotal,
  ) {
    if (draft.paymentMethod != AppPaymentMethods.mixed) {
      return [_SalePaymentDraft.fromBase(draft.paymentMethod, subtotal)];
    }

    return draft.mixedPayments.entries
        .where((entry) => entry.value > 0)
        .map((entry) => _SalePaymentDraft.fromBase(entry.key, entry.value))
        .toList();
  }

  CashSession _applyPaymentsToCashSession({
    required CashSession session,
    required List<_SalePaymentDraft> payments,
    required double commissionTotal,
  }) {
    var expectedCashAmount = session.expectedCashAmount;
    var cashIncome = session.cashIncome;
    var transferIncome = session.transferIncome;
    var terminalIncome = session.terminalIncome;
    var bonusIncome = session.bonusIncome;

    for (final payment in payments) {
      switch (payment.method) {
        case AppPaymentMethods.cash:
          expectedCashAmount += payment.totalCharged;
          cashIncome += payment.totalCharged;
          break;
        case AppPaymentMethods.transfer:
          transferIncome += payment.totalCharged;
          break;
        case AppPaymentMethods.terminalCard:
          terminalIncome += payment.totalCharged;
          break;
        case AppPaymentMethods.terminalBonus:
          bonusIncome += payment.totalCharged;
          break;
      }
    }

    return session.copyWith(
      expectedCashAmount: _roundMoney(expectedCashAmount),
      cashIncome: _roundMoney(cashIncome),
      transferIncome: _roundMoney(transferIncome),
      terminalIncome: _roundMoney(terminalIncome),
      bonusIncome: _roundMoney(bonusIncome),
      commissionTotal: _roundMoney(session.commissionTotal + commissionTotal),
      syncStatus: _pendingSync,
    );
  }

  CashSession _reversePaymentsFromCashSession({
    required CashSession session,
    required List<SalePayment> payments,
    required double commissionTotal,
  }) {
    var expectedCashAmount = session.expectedCashAmount;
    var cashIncome = session.cashIncome;
    var transferIncome = session.transferIncome;
    var terminalIncome = session.terminalIncome;
    var bonusIncome = session.bonusIncome;

    for (final payment in payments) {
      switch (payment.paymentMethod) {
        case AppPaymentMethods.cash:
          expectedCashAmount -= payment.totalCharged;
          cashIncome -= payment.totalCharged;
          break;
        case AppPaymentMethods.transfer:
          transferIncome -= payment.totalCharged;
          break;
        case AppPaymentMethods.terminalCard:
          terminalIncome -= payment.totalCharged;
          break;
        case AppPaymentMethods.terminalBonus:
          bonusIncome -= payment.totalCharged;
          break;
      }
    }

    return session.copyWith(
      expectedCashAmount: _roundMoney(expectedCashAmount),
      cashIncome: _roundMoney(cashIncome),
      transferIncome: _roundMoney(transferIncome),
      terminalIncome: _roundMoney(terminalIncome),
      bonusIncome: _roundMoney(bonusIncome),
      commissionTotal: _roundMoney(session.commissionTotal - commissionTotal),
      syncStatus: _pendingSync,
    );
  }

  double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));

  double _roundQuantity(double value) => double.parse(value.toStringAsFixed(3));
}

class _SalePaymentDraft {
  _SalePaymentDraft.fromBase(this.method, double amount)
    : baseAmount = double.parse(amount.toStringAsFixed(2)),
      commissionRate = AppPaymentCommissions.rateFor(method),
      commissionAmount = double.parse(
        (amount * AppPaymentCommissions.rateFor(method)).toStringAsFixed(2),
      ),
      totalCharged = double.parse(
        (amount * (1 + AppPaymentCommissions.rateFor(method))).toStringAsFixed(
          2,
        ),
      );

  final String method;
  final double baseAmount;
  final double commissionRate;
  final double commissionAmount;
  final double totalCharged;
}
