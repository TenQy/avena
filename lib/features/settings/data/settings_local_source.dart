import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/payment_methods.dart';
import '../../../core/storage/app_files.dart';

class SettingsLocalSource {
  const SettingsLocalSource();

  static const _themeModeKey = 'themeMode';
  static const _businessNameKey = 'businessName';
  static const _businessPhoneKey = 'businessPhone';
  static const _businessAddressKey = 'businessAddress';
  static const _cardCommissionKey = 'cardCommission';
  static const _bonusCommissionKey = 'bonusCommission';

  Future<ThemeMode> readThemeMode() async {
    final file = await _settingsFile();

    if (!await file.exists()) {
      return ThemeMode.light;
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data is Map<String, Object?>) {
        return _themeModeFromName(data[_themeModeKey] as String?);
      }
    } on FormatException {
      await clear();
    }

    return ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final data = await _readSettingsMap();
    data[_themeModeKey] = themeMode.name;
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(data));
  }

  Future<AdministrativeSettings> readAdministrativeSettings() async {
    final data = await _readSettingsMap();

    return AdministrativeSettings(
      businessName: _stringValue(data[_businessNameKey]),
      businessPhone: _stringValue(data[_businessPhoneKey]),
      businessAddress: _stringValue(data[_businessAddressKey]),
      commissionRates: PaymentCommissionRates(
        terminalCard:
            _doubleValue(data[_cardCommissionKey]) ??
            AppPaymentCommissions.terminalCard,
        terminalBonus:
            _doubleValue(data[_bonusCommissionKey]) ??
            AppPaymentCommissions.terminalBonus,
      ),
    );
  }

  Future<void> saveAdministrativeSettings(
    AdministrativeSettings settings,
  ) async {
    final data = await _readSettingsMap();
    data[_businessNameKey] = settings.businessName;
    data[_businessPhoneKey] = settings.businessPhone;
    data[_businessAddressKey] = settings.businessAddress;
    data[_cardCommissionKey] = settings.commissionRates.terminalCard;
    data[_bonusCommissionKey] = settings.commissionRates.terminalBonus;

    final file = await _settingsFile();
    await file.writeAsString(jsonEncode(data));
  }

  Future<void> clear() async {
    final file = await _settingsFile();

    if (await file.exists()) {
      await file.delete();
    }
  }

  ThemeMode _themeModeFromName(String? name) {
    return switch (name) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  Future<Map<String, Object?>> _readSettingsMap() async {
    final file = await _settingsFile();

    if (!await file.exists()) {
      return <String, Object?>{};
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data is Map<String, Object?>) {
        return Map<String, Object?>.from(data);
      }
    } on FormatException {
      await clear();
    }

    return <String, Object?>{};
  }

  String _stringValue(Object? value) {
    if (value is String) {
      return value.trim();
    }

    return '';
  }

  double? _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return null;
  }

  Future<File> _settingsFile() async {
    return AppFiles.settingsFile();
  }
}

class AdministrativeSettings {
  const AdministrativeSettings({
    required this.businessName,
    required this.businessPhone,
    required this.businessAddress,
    required this.commissionRates,
  });

  final String businessName;
  final String businessPhone;
  final String businessAddress;
  final PaymentCommissionRates commissionRates;

  AdministrativeSettings copyWith({
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    PaymentCommissionRates? commissionRates,
  }) {
    return AdministrativeSettings(
      businessName: businessName ?? this.businessName,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      commissionRates: commissionRates ?? this.commissionRates,
    );
  }
}
