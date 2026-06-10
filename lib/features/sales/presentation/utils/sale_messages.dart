import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../data/sales_repository.dart';

void showSaleRegisterResult(BuildContext context, SaleRegisterResult result) {
  final message = switch (result) {
    SaleRegisterResult.success => 'Venta registrada.',
    SaleRegisterResult.unauthorized =>
      'No tienes permisos para registrar ventas.',
    SaleRegisterResult.emptySale => 'Agrega al menos un producto.',
    SaleRegisterResult.emptyCustomerName => 'Ingresa el nombre del cliente.',
    SaleRegisterResult.invalidPayment => 'Revisa los montos del pago.',
    SaleRegisterResult.invalidPendingAmount =>
      'El abono debe ser menor al total pendiente.',
    SaleRegisterResult.cashSessionNotFound => 'No hay una caja abierta.',
    SaleRegisterResult.productNotFound => 'Un producto ya no está disponible.',
    SaleRegisterResult.insufficientStock => 'Stock insuficiente para la venta.',
  };

  showAppSnackBar(context, message);
}

void showSaleCancelResult(BuildContext context, SaleCancelResult result) {
  final message = switch (result) {
    SaleCancelResult.success => 'Venta cancelada.',
    SaleCancelResult.unauthorized => 'No tienes permisos para cancelar ventas.',
    SaleCancelResult.emptyReason => 'Ingresa un motivo de cancelacion.',
    SaleCancelResult.notFound => 'La venta ya no está disponible.',
    SaleCancelResult.alreadyCancelled => 'La venta ya fue cancelada.',
    SaleCancelResult.cashSessionNotFound =>
      'No se encontró la caja asociada a la venta.',
  };

  showAppSnackBar(context, message);
}

void showSaleEditResult(BuildContext context, SaleEditResult result) {
  final message = switch (result) {
    SaleEditResult.success => 'Venta actualizada.',
    SaleEditResult.unauthorized => 'No tienes permisos para editar ventas.',
    SaleEditResult.emptySale => 'Agrega al menos un producto.',
    SaleEditResult.invalidPayment => 'Revisa los montos del pago.',
    SaleEditResult.notFound => 'La venta ya no está disponible.',
    SaleEditResult.notEditable => 'Esta venta no se puede editar.',
    SaleEditResult.cashSessionNotFound =>
      'No se encontró la caja asociada a la venta.',
    SaleEditResult.productNotFound => 'Un producto ya no está disponible.',
    SaleEditResult.insufficientStock => 'Stock insuficiente para la venta.',
  };

  showAppSnackBar(context, message);
}
