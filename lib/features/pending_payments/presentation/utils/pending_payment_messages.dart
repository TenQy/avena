import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../data/pending_payments_repository.dart';

void showPendingPaymentCreateResult(
  BuildContext context,
  PendingPaymentCreateResult result,
) {
  final message = switch (result) {
    PendingPaymentCreateResult.success => 'Pago pendiente creado.',
    PendingPaymentCreateResult.unauthorized =>
      'No tienes permisos para crear pagos pendientes.',
    PendingPaymentCreateResult.emptyCustomerName =>
      'Ingresa el nombre del cliente.',
    PendingPaymentCreateResult.invalidTotalAmount =>
      'Ingresa un monto total valido.',
  };

  showAppSnackBar(context, message);
}

void showPendingPaymentEntryResult(
  BuildContext context,
  PendingPaymentEntryResult result,
) {
  final message = switch (result) {
    PendingPaymentEntryResult.success => 'Abono registrado.',
    PendingPaymentEntryResult.unauthorized =>
      'No tienes permisos para registrar abonos.',
    PendingPaymentEntryResult.paymentNotFound =>
      'El pago pendiente ya no esta disponible.',
    PendingPaymentEntryResult.alreadyCompleted =>
      'Este pago ya fue completado.',
    PendingPaymentEntryResult.invalidAmount => 'Ingresa un monto valido.',
    PendingPaymentEntryResult.exceedsRemainingAmount =>
      'El abono supera el monto pendiente.',
    PendingPaymentEntryResult.invalidPaymentMethod =>
      'Selecciona un metodo de pago valido.',
  };

  showAppSnackBar(context, message);
}
