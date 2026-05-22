class AppPaymentStatuses {
  const AppPaymentStatuses._();

  static const paid = 'paid';
  static const partial = 'partial';
  static const pending = 'pending';
}

class AppSaleStatuses {
  const AppSaleStatuses._();

  static const completed = 'completed';
  static const cancelled = 'cancelled';
}

class AppActivityLogActions {
  const AppActivityLogActions._();

  static const createSale = 'create_sale';
}

class AppActivityLogEntities {
  const AppActivityLogEntities._();

  static const sale = 'sale';
}
