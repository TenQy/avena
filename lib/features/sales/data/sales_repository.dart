import 'package:drift/drift.dart';

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
  invalidPayment,
  cashSessionNotFound,
  productNotFound,
  insufficientStock,
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
