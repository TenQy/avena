class AppPaymentMethods {
  const AppPaymentMethods._();

  static const cash = 'cash';
  static const transfer = 'transfer';
  static const terminalCard = 'terminal_card';
  static const terminalBonus = 'terminal_bonus';
  static const mixed = 'mixed';

  static const all = [cash, transfer, terminalCard, terminalBonus, mixed];

  static const mixable = [cash, transfer, terminalCard, terminalBonus];
}

class AppPaymentCommissions {
  const AppPaymentCommissions._();

  static const cash = 0.0;
  static const transfer = 0.0;
  static const terminalCard = 0.05;
  static const terminalBonus = 0.065;
  static const defaults = PaymentCommissionRates(
    terminalCard: terminalCard,
    terminalBonus: terminalBonus,
  );

  static double rateFor(String method) {
    return defaults.rateFor(method);
  }
}

class PaymentCommissionRates {
  const PaymentCommissionRates({
    required this.terminalCard,
    required this.terminalBonus,
  });

  final double terminalCard;
  final double terminalBonus;

  double rateFor(String method) {
    return switch (method) {
      AppPaymentMethods.terminalCard => terminalCard,
      AppPaymentMethods.terminalBonus => terminalBonus,
      AppPaymentMethods.cash => AppPaymentCommissions.cash,
      AppPaymentMethods.transfer => AppPaymentCommissions.transfer,
      _ => 0,
    };
  }
}
