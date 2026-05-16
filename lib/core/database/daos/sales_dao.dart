import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sale_items.dart';
import '../tables/sale_payments.dart';
import '../tables/sales.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales, SaleItems, SalePayments])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  Stream<List<Sale>> watchSales() => select(sales).watch();

  Future<Sale?> getSaleById(String id) {
    return (select(
      sales,
    )..where((sale) => sale.id.equals(id))).getSingleOrNull();
  }

  Stream<List<SaleItem>> watchItemsBySale(String saleId) {
    return (select(
      saleItems,
    )..where((item) => item.saleId.equals(saleId))).watch();
  }

  Stream<List<SalePayment>> watchPaymentsBySale(String saleId) {
    return (select(
      salePayments,
    )..where((payment) => payment.saleId.equals(saleId))).watch();
  }

  Future<void> insertSale(SalesCompanion sale) => into(sales).insert(sale);

  Future<void> insertSaleItem(SaleItemsCompanion item) {
    return into(saleItems).insert(item);
  }

  Future<void> insertSalePayment(SalePaymentsCompanion payment) {
    return into(salePayments).insert(payment);
  }
}
