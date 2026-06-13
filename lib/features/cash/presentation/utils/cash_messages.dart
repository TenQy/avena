import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../data/cash_repository.dart';

void showOpenCashResult(BuildContext context, OpenCashResult result) {
  final message = switch (result) {
    OpenCashResult.success => 'Caja abierta.',
    OpenCashResult.unauthorized => 'No tienes permisos para abrir caja.',
    OpenCashResult.invalidOpeningAmount => 'Ingresa un monto inicial valido.',
    OpenCashResult.alreadyOpen => 'Ya existe una caja abierta.',
  };

  showAppSnackBar(context, message);
}

void showCloseCashResult(BuildContext context, CloseCashResult result) {
  final message = switch (result) {
    CloseCashResult.success => 'Caja cerrada.',
    CloseCashResult.unauthorized => 'No tienes permisos para cerrar caja.',
    CloseCashResult.notFound => 'La caja abierta ya no está disponible.',
  };

  showAppSnackBar(context, message);
}

void showCashMovementResult(BuildContext context, CashMovementResult result) {
  final message = switch (result) {
    CashMovementResult.success => 'Movimiento registrado.',
    CashMovementResult.unauthorized =>
      'No tienes permisos para modificar caja.',
    CashMovementResult.invalidAmount => 'Ingresa un monto valido.',
    CashMovementResult.amountTooHigh => 'El monto maximo es \$999999.00.',
    CashMovementResult.emptyReason => 'Ingresa un motivo.',
    CashMovementResult.insufficientCash =>
      'No puedes retirar mas dinero del disponible en caja.',
    CashMovementResult.sessionNotFound =>
      'La caja abierta ya no está disponible.',
  };

  showAppSnackBar(context, message);
}

void showUpdateOpeningCashResult(
  BuildContext context,
  UpdateOpeningCashResult result,
) {
  final message = switch (result) {
    UpdateOpeningCashResult.success => 'Dinero inicial actualizado.',
    UpdateOpeningCashResult.unauthorized =>
      'No tienes permisos para modificar caja.',
    UpdateOpeningCashResult.invalidAmount => 'Ingresa un monto inicial valido.',
    UpdateOpeningCashResult.amountTooHigh => 'El monto maximo es \$999999.00.',
    UpdateOpeningCashResult.sessionNotFound =>
      'La caja abierta ya no está disponible.',
  };

  showAppSnackBar(context, message);
}
