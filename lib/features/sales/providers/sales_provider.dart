import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/sales_repository.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.watch(databaseProvider));
});

class SalesHistoryFilter {
  const SalesHistoryFilter({required this.date, this.paymentMethod});

  final DateTime date;
  final String? paymentMethod;

  @override
  bool operator ==(Object other) {
    return other is SalesHistoryFilter &&
        date.year == other.date.year &&
        date.month == other.date.month &&
        date.day == other.date.day &&
        paymentMethod == other.paymentMethod;
  }

  @override
  int get hashCode =>
      Object.hash(date.year, date.month, date.day, paymentMethod);
}

final salesHistoryProvider =
    StreamProvider.family<List<Sale>, SalesHistoryFilter>((ref, filter) {
      final start = DateTime(
        filter.date.year,
        filter.date.month,
        filter.date.day,
      );
      final end = start.add(const Duration(days: 1));
      final repository = ref.watch(salesRepositoryProvider);

      if (filter.paymentMethod == null) {
        return repository.watchSalesBetween(start, end);
      }

      return repository.watchSalesBetweenByPayment(
        start,
        end,
        filter.paymentMethod!,
      );
    });

final saleItemsBySaleProvider = StreamProvider.family<List<SaleItem>, String>((
  ref,
  saleId,
) {
  return ref.watch(salesRepositoryProvider).watchItemsBySale(saleId);
});

final salePaymentsBySaleProvider =
    StreamProvider.family<List<SalePayment>, String>((ref, saleId) {
      return ref.watch(salesRepositoryProvider).watchPaymentsBySale(saleId);
    });
