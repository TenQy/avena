import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sale_items.dart';
import '../tables/sale_payments.dart';
import '../tables/sales.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales, SaleItems, SalePayments])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  Stream<List<Sale>> watchSalesBetween(DateTime start, DateTime end) {
    return (select(sales)
          ..where(
            (sale) =>
                sale.createdAt.isBiggerOrEqualValue(start) &
                sale.createdAt.isSmallerThanValue(end),
          )
          ..orderBy([(sale) => OrderingTerm.desc(sale.createdAt)]))
        .watch();
  }

  Stream<List<Sale>> watchSalesBetweenByPayment(
    DateTime start,
    DateTime end,
    String paymentMethod,
  ) {
    final query =
        select(sales).join([
            innerJoin(salePayments, salePayments.saleId.equalsExp(sales.id)),
          ])
          ..where(
            sales.createdAt.isBiggerOrEqualValue(start) &
                sales.createdAt.isSmallerThanValue(end) &
                salePayments.paymentMethod.equals(paymentMethod),
          )
          ..orderBy([OrderingTerm.desc(sales.createdAt)]);

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(sales)).toList(),
    );
  }

  Future<Sale?> getSaleById(String id) {
    return (select(
      sales,
    )..where((sale) => sale.id.equals(id))).getSingleOrNull();
  }

  Future<List<SaleItem>> getItemsBySale(String saleId) {
    return (select(
      saleItems,
    )..where((item) => item.saleId.equals(saleId))).get();
  }

  Stream<List<SaleItem>> watchItemsBySale(String saleId) {
    return (select(
      saleItems,
    )..where((item) => item.saleId.equals(saleId))).watch();
  }

  Future<List<SalePayment>> getPaymentsBySale(String saleId) {
    return (select(
      salePayments,
    )..where((payment) => payment.saleId.equals(saleId))).get();
  }

  Stream<List<SalePayment>> watchPaymentsBySale(String saleId) {
    return (select(
      salePayments,
    )..where((payment) => payment.saleId.equals(saleId))).watch();
  }

  Future<void> insertSale(SalesCompanion sale) => into(sales).insert(sale);

  Future<bool> updateSale(Sale sale) => update(sales).replace(sale);

  Future<void> insertSaleItem(SaleItemsCompanion item) {
    return into(saleItems).insert(item);
  }

  Future<void> insertSalePayment(SalePaymentsCompanion payment) {
    return into(salePayments).insert(payment);
  }
}
