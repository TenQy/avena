import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/logs_repository.dart';

class LogsFilters {
  const LogsFilters({
    this.userId,
    this.action,
    this.selectedDate,
  });

  final String? userId;
  final String? action;
  final DateTime? selectedDate;

  LogsFilters copyWith({
    String? userId,
    bool clearUserId = false,
    String? action,
    bool clearAction = false,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
  }) {
    return LogsFilters(
      userId: clearUserId ? null : userId ?? this.userId,
      action: clearAction ? null : action ?? this.action,
      selectedDate: clearSelectedDate
          ? null
          : selectedDate ?? this.selectedDate,
    );
  }
}

class LogsFiltersNotifier extends StateNotifier<LogsFilters> {
  LogsFiltersNotifier() : super(const LogsFilters());

  void setUserId(String? userId) {
    state = state.copyWith(userId: userId, clearUserId: userId == null);
  }

  void setAction(String? action) {
    state = state.copyWith(action: action, clearAction: action == null);
  }

  void setDate(DateTime? date) {
    state = state.copyWith(
      selectedDate: date == null ? null : DateTime(date.year, date.month, date.day),
      clearSelectedDate: date == null,
    );
  }

  void clear() {
    state = const LogsFilters();
  }
}

final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  return LogsRepository(ref.watch(databaseProvider));
});

final logsProvider = StreamProvider<List<ActivityLog>>((ref) {
  return ref.watch(logsRepositoryProvider).watchActivityLogs();
});

final logsFiltersProvider =
    StateNotifierProvider<LogsFiltersNotifier, LogsFilters>((ref) {
      return LogsFiltersNotifier();
    });

final filteredLogsProvider = Provider<AsyncValue<List<ActivityLog>>>((ref) {
  final logsState = ref.watch(logsProvider);
  final filters = ref.watch(logsFiltersProvider);

  return logsState.whenData((logs) {
    return logs.where((log) {
      if (filters.userId != null && log.userId != filters.userId) {
        return false;
      }

      if (filters.action != null && log.action != filters.action) {
        return false;
      }

      final selectedDate = filters.selectedDate;
      if (selectedDate != null) {
        final createdAt = log.createdAt;
        final logDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
        if (logDate != selectedDate) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});
