import '../../../../core/maintenance/local_maintenance_service.dart';

String settingsMoney(double value) => '\$${value.toStringAsFixed(2)}';

String settingsPercent(double rate) {
  final value = rate * 100;
  return value == value.roundToDouble()
      ? '${value.toStringAsFixed(0)}%'
      : '${value.toStringAsFixed(1)}%';
}

String settingsPercentInput(double rate) {
  final value = rate * 100;
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

String maintenanceErrorMessage(Object error) {
  if (error is MaintenanceException) {
    return error.message;
  }

  return 'No se pudo completar la accion de mantenimiento.';
}
