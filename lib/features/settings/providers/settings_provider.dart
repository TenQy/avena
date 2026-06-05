import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
