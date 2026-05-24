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
