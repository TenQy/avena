import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/payment_methods.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/maintenance/local_maintenance_service.dart';
import '../../authentication/providers/auth_provider.dart';
import '../data/settings_local_source.dart';

final settingsLocalSourceProvider = Provider<SettingsLocalSource>((ref) {
  return const SettingsLocalSource();
});

final personalSettingsProvider =
    StateNotifierProvider<PersonalSettingsController, AsyncValue<ThemeMode>>((
      ref,
    ) {
      return PersonalSettingsController(ref.watch(settingsLocalSourceProvider));
    });

final basicConnectionProvider = FutureProvider<BasicConnectionStatus>((ref) {
  return BasicConnectionStatus.check();
});

final administrativeSettingsProvider =
    StateNotifierProvider<
      AdministrativeSettingsController,
      AsyncValue<AdministrativeSettings>
    >((ref) {
      return AdministrativeSettingsController(
        ref.watch(settingsLocalSourceProvider),
      );
    });

final localMaintenanceServiceProvider = Provider<LocalMaintenanceService>((
  ref,
) {
  return LocalMaintenanceService(ref.watch(databaseProvider));
});

final maintenanceProvider =
    StateNotifierProvider<MaintenanceController, AsyncValue<void>>((ref) {
      return MaintenanceController(
        ref,
        ref.watch(localMaintenanceServiceProvider),
      );
    });

final localSyncStatusProvider = StreamProvider<LocalSyncStatus>((ref) {
  return ref.watch(databaseProvider).syncQueueDao.watchPendingOperations().map((
    operations,
  ) {
    final failedCount = operations
        .where((operation) => operation.lastError != null)
        .length;

    return LocalSyncStatus(
      pendingCount: operations.length,
      failedCount: failedCount,
    );
  });
});

class PersonalSettingsController extends StateNotifier<AsyncValue<ThemeMode>> {
  PersonalSettingsController(this._localSource)
    : super(const AsyncValue.loading()) {
    load();
  }

  final SettingsLocalSource _localSource;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_localSource.readThemeMode);
  }

  Future<void> setDarkMode(bool enabled) async {
    final themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    state = AsyncValue.data(themeMode);
    await _localSource.saveThemeMode(themeMode);
  }
}

class AdministrativeSettingsController
    extends StateNotifier<AsyncValue<AdministrativeSettings>> {
  AdministrativeSettingsController(this._localSource)
    : super(const AsyncValue.loading()) {
    load();
  }

  final SettingsLocalSource _localSource;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_localSource.readAdministrativeSettings);
  }

  Future<void> saveBusinessInfo({
    required String businessName,
    required String businessPhone,
    required String businessAddress,
  }) async {
    final current =
        state.valueOrNull ?? await _localSource.readAdministrativeSettings();
    final next = current.copyWith(
      businessName: businessName.trim(),
      businessPhone: businessPhone.trim(),
      businessAddress: businessAddress.trim(),
    );

    state = AsyncValue.data(next);
    await _localSource.saveAdministrativeSettings(next);
  }

  Future<void> saveCommissionRates({
    required double cardPercent,
    required double bonusPercent,
  }) async {
    final current =
        state.valueOrNull ?? await _localSource.readAdministrativeSettings();
    final next = current.copyWith(
      commissionRates: PaymentCommissionRates(
        terminalCard: cardPercent / 100,
        terminalBonus: bonusPercent / 100,
      ),
    );

    state = AsyncValue.data(next);
    await _localSource.saveAdministrativeSettings(next);
  }
}

class MaintenanceController extends StateNotifier<AsyncValue<void>> {
  MaintenanceController(this._ref, this._repository)
    : super(const AsyncValue.data(null));

  final Ref _ref;
  final LocalMaintenanceService _repository;

  Future<BackupResult> exportLocalBackup({required User actor}) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.exportLocalBackup(actor: actor);
      state = const AsyncValue.data(null);
      _invalidateMaintenanceViews();

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<BackupResult> restoreLatestBackup({required User actor}) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.restoreLatestBackup(actor: actor);
      state = const AsyncValue.data(null);
      _ref.invalidate(databaseProvider);
      _ref.invalidate(authProvider);
      _ref.invalidate(personalSettingsProvider);
      _ref.invalidate(administrativeSettingsProvider);
      _invalidateMaintenanceViews();

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> resetOperationalData({required User actor}) {
    return _runMaintenanceAction(() async {
      await _repository.resetOperationalData(actor: actor);
    });
  }

  Future<void> clearActivityLogs({required User actor}) {
    return _runMaintenanceAction(() async {
      await _repository.clearActivityLogs(actor: actor);
    });
  }

  Future<void> clearSyncQueue({required User actor}) {
    return _runMaintenanceAction(() async {
      await _repository.clearSyncQueue(actor: actor);
    });
  }

  Future<void> resetApplicationData({required User actor}) async {
    state = const AsyncValue.loading();

    try {
      await _repository.resetApplicationData(actor: actor);
      state = const AsyncValue.data(null);
      _ref.invalidate(databaseProvider);
      _ref.invalidate(authProvider);
      _ref.invalidate(personalSettingsProvider);
      _ref.invalidate(administrativeSettingsProvider);
      _invalidateMaintenanceViews();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _runMaintenanceAction(Future<void> Function() action) async {
    state = const AsyncValue.loading();

    try {
      await action();
      state = const AsyncValue.data(null);
      _invalidateMaintenanceViews();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  void _invalidateMaintenanceViews() {
    _ref.invalidate(localSyncStatusProvider);
  }
}

class LocalSyncStatus {
  const LocalSyncStatus({
    required this.pendingCount,
    required this.failedCount,
  });

  final int pendingCount;
  final int failedCount;
}

class BasicConnectionStatus {
  const BasicConnectionStatus({
    required this.hasInternet,
    required this.checkedAt,
  });

  final bool hasInternet;
  final DateTime checkedAt;

  static Future<BasicConnectionStatus> check() async {
    var hasInternet = false;

    try {
      final addresses = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 2));
      hasInternet =
          addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty;
    } on SocketException {
      hasInternet = false;
    } on TimeoutException {
      hasInternet = false;
    }

    return BasicConnectionStatus(
      hasInternet: hasInternet,
      checkedAt: DateTime.now(),
    );
  }
}
