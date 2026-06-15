import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../storage/app_files.dart';
import 'daos/activity_logs_dao.dart';
import 'daos/cash_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/pending_payments_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/users_dao.dart';
import 'database_seed.dart';
import 'tables/activity_logs.dart';
import 'tables/cash_movements.dart';
import 'tables/cash_sessions.dart';
import 'tables/categories.dart';
import 'tables/employee_sessions.dart';
import 'tables/pending_payment_entries.dart';
import 'tables/pending_payments.dart';
import 'tables/products.dart';
import 'tables/sale_items.dart';
import 'tables/sale_payments.dart';
import 'tables/sales.dart';
import 'tables/subcategories.dart';
import 'tables/sync_queue.dart';
import 'tables/users.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    EmployeeSessions,
    Categories,
    Subcategories,
    Products,
    CashSessions,
    CashMovements,
    Sales,
    SaleItems,
    SalePayments,
    PendingPayments,
    PendingPaymentEntries,
    ActivityLogs,
    SyncQueue,
  ],
  daos: [
    UsersDao,
    InventoryDao,
    CashDao,
    SalesDao,
    PendingPaymentsDao,
    ActivityLogsDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(products, products.cost);
          await migrator.addColumn(saleItems, saleItems.unitCostSnapshot);
          await migrator.addColumn(saleItems, saleItems.costSubtotalSnapshot);
        }
        if (from < 3) {
          await migrator.addColumn(sales, sales.cashReceivedAmount);
        }
      },
      beforeOpen: (details) async {
        await DatabaseSeed.ensureInitialData(this);
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file = await AppFiles.databaseFile();

    return NativeDatabase.createInBackground(file);
  });
}
