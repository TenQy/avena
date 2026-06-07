import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/payment_methods.dart';
import '../../../core/database/database_provider.dart';
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

class LocalSyncStatus {
  const LocalSyncStatus({required this.pendingCount, required this.failedCount});

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
      hasInternet = addresses.isNotEmpty && addresses.first.rawAddress.isNotEmpty;
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
