import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_products.dart';
import '../../../core/constants/payment_methods.dart';
import '../../../core/database/app_database.dart';
import '../presentation/models/sale_draft_item.dart';

final currentSaleProvider =
    StateNotifierProvider<CurrentSaleController, CurrentSaleState>((ref) {
      return CurrentSaleController();
    });

class CurrentSaleState {
  const CurrentSaleState({
    this.items = const [],
    this.paymentMethod = AppPaymentMethods.cash,
    this.mixedPayments = const {},
  });

  final List<SaleDraftItem> items;
  final String paymentMethod;
  final Map<String, double> mixedPayments;

  double get subtotal {
    return items.fold(0, (total, item) => total + item.subtotal);
  }

  double get commission {
    if (paymentMethod == AppPaymentMethods.mixed) {
      return mixedPayments.entries.fold(0, (total, entry) {
        return total + entry.value * AppPaymentCommissions.rateFor(entry.key);
      });
    }

    return subtotal * AppPaymentCommissions.rateFor(paymentMethod);
  }

  double get total => subtotal + commission;

  double get mixedTotal {
    return mixedPayments.entries.fold(0, (total, entry) {
      return total +
          entry.value * (1 + AppPaymentCommissions.rateFor(entry.key));
    });
  }

  CurrentSaleState copyWith({
    List<SaleDraftItem>? items,
    String? paymentMethod,
    Map<String, double>? mixedPayments,
  }) {
    return CurrentSaleState(
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      mixedPayments: mixedPayments ?? this.mixedPayments,
    );
  }
}

class CurrentSaleController extends StateNotifier<CurrentSaleState> {
  CurrentSaleController() : super(const CurrentSaleState());

  void addProduct(Product product) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == product.id);

    if (index == -1) {
      items.add(SaleDraftItem(product: product, quantity: 1));
    } else {
      final item = items[index];
      items[index] = item.copyWith(
        quantity: item.quantity + 1,
        customSubtotal: item.customSubtotal + product.price,
      );
    }

    state = state.copyWith(items: items);
  }

  void increaseQuantity(SaleDraftItem item) {
    _updateItem(item, (currentItem) {
      return currentItem.copyWith(
        quantity: currentItem.quantity + 1,
        customSubtotal: currentItem.customSubtotal + currentItem.product.price,
      );
    });
  }

  void decreaseQuantity(SaleDraftItem item) {
    final items = [...state.items];
    final index = items.indexWhere(
      (currentItem) => currentItem.product.id == item.product.id,
    );

    if (index == -1) {
      return;
    }

    final nextQuantity = items[index].quantity - 1;
    if (nextQuantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(
        quantity: nextQuantity,
        customSubtotal:
            items[index].customSubtotal - items[index].product.price,
      );
    }

    state = state.copyWith(items: items);
  }

  void applyBulkPortion(SaleDraftItem item, AppBulkPortion portion) {
    _updateItem(item, (currentItem) {
      return currentItem.copyWith(
        quantity: portion.kilogramFactor,
        customSubtotal: currentItem.product.price * portion.kilogramFactor,
      );
    });
  }

  void updateBulkItem({
    required SaleDraftItem item,
    required double quantity,
    required double subtotal,
  }) {
    _updateItem(item, (currentItem) {
      return currentItem.copyWith(quantity: quantity, customSubtotal: subtotal);
    });
  }

  void removeItem(SaleDraftItem item) {
    state = state.copyWith(
      items: state.items
          .where((currentItem) => currentItem.product.id != item.product.id)
          .toList(),
    );
  }

  void selectPaymentMethod(String method) {
    if (method == AppPaymentMethods.mixed) {
      state = state.copyWith(paymentMethod: method);
      return;
    }

    state = state.copyWith(paymentMethod: method, mixedPayments: const {});
  }

  void updateMixedPayment(String method, double amount) {
    final payments = {...state.mixedPayments};

    if (amount <= 0) {
      payments.remove(method);
    } else {
      payments[method] = amount;
    }

    state = state.copyWith(mixedPayments: payments);
  }

  void _updateItem(
    SaleDraftItem item,
    SaleDraftItem Function(SaleDraftItem currentItem) update,
  ) {
    final items = [...state.items];
    final index = items.indexWhere(
      (currentItem) => currentItem.product.id == item.product.id,
    );

    if (index == -1) {
      return;
    }

    items[index] = update(items[index]);
    state = state.copyWith(items: items);
  }
}
