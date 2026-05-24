import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../data/sales_repository.dart';

void showSaleRegisterResult(BuildContext context, SaleRegisterResult result) {
  final message = switch (result) {
    SaleRegisterResult.success => 'Venta registrada.',
    SaleRegisterResult.unauthorized =>
      'No tienes permisos para registrar ventas.',
    SaleRegisterResult.emptySale => 'Agrega al menos un producto.',
    SaleRegisterResult.invalidPayment => 'Revisa los montos del pago.',
    SaleRegisterResult.cashSessionNotFound => 'No hay una caja abierta.',
    SaleRegisterResult.productNotFound => 'Un producto ya no esta disponible.',
    SaleRegisterResult.insufficientStock => 'Stock insuficiente para la venta.',
  };

  showAppSnackBar(context, message);
}

void showSaleCancelResult(BuildContext context, SaleCancelResult result) {
  final message = switch (result) {
    SaleCancelResult.success => 'Venta cancelada.',
    SaleCancelResult.unauthorized => 'No tienes permisos para cancelar ventas.',
    SaleCancelResult.emptyReason => 'Ingresa un motivo de cancelacion.',
    SaleCancelResult.notFound => 'La venta ya no esta disponible.',
    SaleCancelResult.alreadyCancelled => 'La venta ya fue cancelada.',
    SaleCancelResult.cashSessionNotFound =>
      'No se encontro la caja asociada a la venta.',
  };

  showAppSnackBar(context, message);
}
