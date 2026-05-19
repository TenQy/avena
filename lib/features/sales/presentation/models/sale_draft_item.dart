import '../../../../core/database/app_database.dart';

class SaleDraftItem {
  SaleDraftItem({
    required this.product,
    required this.quantity,
    double? customSubtotal,
  }) : customSubtotal = customSubtotal ?? product.price * quantity;

  final Product product;
  final double quantity;
  final double customSubtotal;

  double get subtotal => customSubtotal;

  SaleDraftItem copyWith({double? quantity, double? customSubtotal}) {
    return SaleDraftItem(
      product: product,
      quantity: quantity ?? this.quantity,
      customSubtotal: customSubtotal ?? this.customSubtotal,
    );
  }
}
