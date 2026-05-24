class AppPendingPaymentStatuses {
  const AppPendingPaymentStatuses._();

  static const pending = 'pending';
  static const partial = 'partial';
  static const completed = 'completed';
}

class AppPendingPaymentLogActions {
  const AppPendingPaymentLogActions._();

  static const createPendingPayment = 'create_pending_payment';
}

class AppPendingPaymentLogEntities {
  const AppPendingPaymentLogEntities._();

  static const pendingPayment = 'pending_payment';
}
