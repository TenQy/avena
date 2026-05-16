import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(appDir.path, 'tienda.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
