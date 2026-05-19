class AppProductTypes {
  const AppProductTypes._();

  static const unit = 'unit';
  static const bulk = 'bulk';
}

class AppProductPriceUnits {
  const AppProductPriceUnits._();

  static const unit = 'unit';
  static const kilogram = 'kg';
}

class AppBulkPortion {
  const AppBulkPortion({required this.label, required this.kilogramFactor});

  final String label;
  final double kilogramFactor;
}

class AppBulkPortions {
  const AppBulkPortions._();

  static const oneKilogram = AppBulkPortion(label: '1 kg', kilogramFactor: 1);
  static const halfKilogram = AppBulkPortion(
    label: '1/2 kg',
    kilogramFactor: 0.5,
  );
  static const oneHundredGrams = AppBulkPortion(
    label: '100 g',
    kilogramFactor: 0.1,
  );
  static const fiftyGrams = AppBulkPortion(label: '50 g', kilogramFactor: 0.05);

  static const standard = [
    oneKilogram,
    halfKilogram,
    oneHundredGrams,
    fiftyGrams,
  ];

  static const salesQuick = [oneKilogram, halfKilogram, oneHundredGrams];
}
