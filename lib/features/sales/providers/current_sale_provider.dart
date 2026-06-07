import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_products.dart';
import '../../../core/constants/payment_methods.dart';
import '../../../core/database/app_database.dart';
import '../../settings/providers/settings_provider.dart';
import '../presentation/models/sale_draft_item.dart';

final currentSaleProvider =
    StateNotifierProvider<CurrentSaleController, CurrentSaleState>((ref) {
      final controller = CurrentSaleController();
      ref.listen(administrativeSettingsProvider, (_, next) {
        final settings = next.valueOrNull;
        if (settings != null) {
          controller.updateCommissionRates(settings.commissionRates);
        }
      }, fireImmediately: true);

      return controller;
    });

class CurrentSaleState {
  const CurrentSaleState({
    this.items = const [],
    this.paymentMethod = AppPaymentMethods.cash,
    this.mixedPayments = const {},
    this.commissionRates = AppPaymentCommissions.defaults,
  });

  final List<SaleDraftItem> items;
  final String paymentMethod;
  final Map<String, double> mixedPayments;
  final PaymentCommissionRates commissionRates;

  double get subtotal {
    return items.fold(0, (total, item) => total + item.subtotal);
  }

  double get commission {
    if (paymentMethod == AppPaymentMethods.mixed) {
      return mixedPayments.entries.fold(0, (total, entry) {
        return total + entry.value * commissionRates.rateFor(entry.key);
      });
    }

    return subtotal * commissionRates.rateFor(paymentMethod);
  }

  double get total => subtotal + commission;

  double get mixedTotal {
    return mixedPayments.entries.fold(0, (total, entry) {
      return total +
          entry.value * (1 + commissionRates.rateFor(entry.key));
    });
  }

  bool get canRegister {
    if (items.isEmpty) {
      return false;
    }

    if (paymentMethod != AppPaymentMethods.mixed) {
      return AppPaymentMethods.all.contains(paymentMethod);
    }

    return mixedPayments.isNotEmpty &&
        (mixedPayments.values.fold(0.0, (total, amount) => total + amount) -
                    subtotal)
                .abs() <=
            0.01;
  }

  CurrentSaleState copyWith({
    List<SaleDraftItem>? items,
    String? paymentMethod,
    Map<String, double>? mixedPayments,
    PaymentCommissionRates? commissionRates,
  }) {
    return CurrentSaleState(
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      mixedPayments: mixedPayments ?? this.mixedPayments,
      commissionRates: commissionRates ?? this.commissionRates,
    );
  }
}

class CurrentSaleController extends StateNotifier<CurrentSaleState> {
  CurrentSaleController() : super(const CurrentSaleState());

  void addProduct(Product product) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.product.id == product.id);

    if (index == -1) {
      final initialQuantity = _initialQuantityFor(product);
      if (initialQuantity <= 0) {
        return;
      }

      items.add(SaleDraftItem(product: product, quantity: initialQuantity));
    } else {
      final item = items[index];
      if (!_hasAvailableStock(item, item.quantity + 1)) {
        return;
      }

      items[index] = item.copyWith(
        quantity: item.quantity + 1,
        customSubtotal: item.customSubtotal + product.price,
      );
    }

    state = state.copyWith(items: items);
  }

  void increaseQuantity(SaleDraftItem item) {
    _updateItem(item, (currentItem) {
      if (!_hasAvailableStock(currentItem, currentItem.quantity + 1)) {
        return currentItem;
      }

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
      if (!_hasAvailableStock(currentItem, portion.kilogramFactor)) {
        return currentItem;
      }

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
      if (!_hasAvailableStock(currentItem, quantity)) {
        return currentItem;
      }

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

  void reset() {
    state = CurrentSaleState(commissionRates: state.commissionRates);
  }

  void updateCommissionRates(PaymentCommissionRates commissionRates) {
    state = state.copyWith(commissionRates: commissionRates);
  }

  void syncProducts(List<Product> products) {
    if (state.items.isEmpty) {
      return;
    }

    var changed = false;
    final syncedItems = <SaleDraftItem>[];

    for (final item in state.items) {
      final product = products.where(
        (product) => product.id == item.product.id,
      );
      if (product.isEmpty) {
        syncedItems.add(item);
        continue;
      }

      final currentProduct = product.first;
      var nextQuantity = item.quantity;
      var nextSubtotal = item.customSubtotal;

      if (currentProduct.trackStock &&
          nextQuantity > (currentProduct.stockQuantity ?? 0)) {
        nextQuantity = currentProduct.stockQuantity ?? 0;
        nextSubtotal = currentProduct.price * nextQuantity;
      }

      final syncedItem = item.copyWith(
        product: currentProduct,
        quantity: nextQuantity,
        customSubtotal: nextSubtotal,
      );
      syncedItems.add(syncedItem);
      changed =
          changed ||
          syncedItem.product != item.product ||
          syncedItem.quantity != item.quantity ||
          syncedItem.customSubtotal != item.customSubtotal;
    }

    if (!changed) {
      return;
    }

    state = state.copyWith(
      items: syncedItems.where((item) => item.quantity > 0).toList(),
    );
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

  bool _hasAvailableStock(SaleDraftItem item, double nextQuantity) {
    final product = item.product;
    if (!product.trackStock) {
      return true;
    }

    return nextQuantity <= (product.stockQuantity ?? 0);
  }

  double _initialQuantityFor(Product product) {
    if (!product.trackStock) {
      return 1;
    }

    final stockQuantity = product.stockQuantity ?? 0;
    if (stockQuantity <= 0) {
      return 0;
    }

    if (product.productType == AppProductTypes.bulk && stockQuantity < 1) {
      return stockQuantity;
    }

    return stockQuantity >= 1 ? 1 : 0;
  }
}
