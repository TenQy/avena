class AppPaymentMethods {
  const AppPaymentMethods._();

  static const cash = 'cash';
  static const transfer = 'transfer';
  static const terminalCard = 'terminal_card';
  static const terminalBonus = 'terminal_bonus';
  static const mixed = 'mixed';

  static const all = [cash, transfer, terminalCard, terminalBonus, mixed];
}

class AppPaymentCommissions {
  const AppPaymentCommissions._();

  static const cash = 0.0;
  static const transfer = 0.0;
  static const terminalCard = 0.05;
  static const terminalBonus = 0.065;
}
