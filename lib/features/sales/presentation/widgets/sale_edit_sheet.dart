import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_products.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../inventory/providers/inventory_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../data/sales_repository.dart';
import '../../providers/sales_provider.dart';
import '../models/sale_draft_item.dart';
import 'bulk_sale_item_sheet.dart';
import 'sale_items_card.dart';
import 'sale_payment_methods_card.dart';
import 'sale_product_search_card.dart';

class SaleEditSheet extends ConsumerStatefulWidget {
  const SaleEditSheet({super.key, required this.actor, required this.sale});

  final User actor;
  final Sale sale;

  static Future<SaleEditResult?> show(
    BuildContext context, {
    required User actor,
    required Sale sale,
  }) {
    return showModalBottomSheet<SaleEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SaleEditSheet(actor: actor, sale: sale),
    );
  }

  @override
  ConsumerState<SaleEditSheet> createState() => _SaleEditSheetState();
}

class _SaleEditSheetState extends ConsumerState<SaleEditSheet> {
  final _searchController = TextEditingController();
  final _originalQuantitiesByProductId = <String, double>{};

  List<SaleDraftItem> _items = const [];
  String _paymentMethod = AppPaymentMethods.cash;
  Map<String, double> _mixedPayments = const {};
  PaymentCommissionRates _commissionRates = AppPaymentCommissions.defaults;
  bool _isInitialized = false;
  bool _isSaving = false;

  double get _subtotal {
    return _items.fold(0, (total, item) => total + item.subtotal);
  }

  double get _commission {
    if (_paymentMethod == AppPaymentMethods.mixed) {
      return _mixedPayments.entries.fold(0, (total, entry) {
        return total + entry.value * _commissionRates.rateFor(entry.key);
      });
    }

    return _subtotal * _commissionRates.rateFor(_paymentMethod);
  }

  double get _total => _subtotal + _commission;

  double get _mixedTotal {
    return _mixedPayments.entries.fold(0, (total, entry) {
      return total + entry.value * (1 + _commissionRates.rateFor(entry.key));
    });
  }

  bool get _canSave {
    if (_items.isEmpty) {
      return false;
    }

    if (_paymentMethod != AppPaymentMethods.mixed) {
      return AppPaymentMethods.all.contains(_paymentMethod);
    }

    final mixedBaseTotal = _mixedPayments.values.fold(
      0.0,
      (total, amount) => total + amount,
    );

    return _mixedPayments.isNotEmpty &&
        (mixedBaseTotal - _subtotal).abs() <= 0.01;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleItemsState = ref.watch(saleItemsBySaleProvider(widget.sale.id));
    final paymentsState = ref.watch(salePaymentsBySaleProvider(widget.sale.id));
    final productsState = ref.watch(productsProvider);
    final settingsState = ref.watch(administrativeSettingsProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.92,
          child: saleItemsState.when(
            data: (saleItems) {
              return paymentsState.when(
                data: (payments) {
                  return productsState.when(
                    data: (products) {
                      final settings = settingsState.valueOrNull;
                      _initializeOnce(
                        saleItems: saleItems,
                        payments: payments,
                        products: products,
                        fallbackRates:
                            settings?.commissionRates ??
                            AppPaymentCommissions.defaults,
                      );

                      return _buildForm(products);
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const EmptyState(
                      icon: Icons.error_outline_rounded,
                      message: 'No se pudieron cargar los productos',
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const EmptyState(
                  icon: Icons.error_outline_rounded,
                  message: 'No se pudieron cargar los pagos',
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const EmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar los productos de la venta',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<Product> products) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderFor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Editar venta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Cerrar editor',
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ajusta productos, cantidades y método de pago.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SaleProductSearchCard(
          controller: _searchController,
          products: _productsWithRestoredStock(products),
          query: _searchController.text,
          onAddProduct: _addProduct,
        ),
        const SizedBox(height: AppSpacing.lg),
        SaleItemsCard(
          items: _items,
          onIncreaseQuantity: _increaseQuantity,
          onDecreaseQuantity: _decreaseQuantity,
          onUpdateUnitQuantity: _updateUnitQuantity,
          onEditBulkItem: _showBulkItemSheet,
          onApplyBulkPortion: _applyBulkPortion,
          onRemoveItem: _removeItem,
        ),
        const SizedBox(height: AppSpacing.lg),
        SalePaymentMethodsCard(
          selectedMethod: _paymentMethod,
          mixedPayments: _mixedPayments,
          subtotal: _subtotal,
          total: _total,
          mixedTotal: _mixedTotal,
          commissionRates: _commissionRates,
          onMethodSelected: _selectPaymentMethod,
          onMixedPaymentChanged: _updateMixedPayment,
        ),
        const SizedBox(height: AppSpacing.lg),
        _SaleEditTotalCard(
          subtotal: _subtotal,
          commission: _commission,
          isSaving: _isSaving,
          canSave: _canSave,
          onSave: _saveChanges,
        ),
      ],
    );
  }

  void _initializeOnce({
    required List<SaleItem> saleItems,
    required List<SalePayment> payments,
    required List<Product> products,
    required PaymentCommissionRates fallbackRates,
  }) {
    if (_isInitialized) {
      return;
    }

    final productsById = {for (final product in products) product.id: product};
    final originalItems = <SaleDraftItem>[];

    for (final item in saleItems) {
      final product = productsById[item.productId];
      if (product == null) {
        continue;
      }

      _originalQuantitiesByProductId[item.productId] =
          (_originalQuantitiesByProductId[item.productId] ?? 0) + item.quantity;
      final restoredStock = product.trackStock
          ? (product.stockQuantity ?? 0) + item.quantity
          : product.stockQuantity;
      final snapshotProduct = product.copyWith(
        name: item.productNameSnapshot,
        brand: Value(item.productBrandSnapshot),
        productType: item.productTypeSnapshot,
        price: item.unitPriceSnapshot,
        cost: Value(item.unitCostSnapshot),
        priceUnit: item.priceUnitSnapshot,
        stockQuantity: Value(restoredStock),
      );

      originalItems.add(
        SaleDraftItem(
          product: snapshotProduct,
          quantity: item.quantity,
          customSubtotal: item.subtotal,
        ),
      );
    }

    _items = originalItems;
    _paymentMethod = _initialPaymentMethod(payments);
    _mixedPayments = _initialMixedPayments(payments);
    _commissionRates = _initialCommissionRates(payments, fallbackRates);
    _isInitialized = true;
  }

  List<Product> _productsWithRestoredStock(List<Product> products) {
    return [
      for (final product in products)
        if (product.trackStock &&
            _originalQuantitiesByProductId.containsKey(product.id))
          product.copyWith(
            stockQuantity: Value(
              (product.stockQuantity ?? 0) +
                  _originalQuantitiesByProductId[product.id]!,
            ),
          )
        else
          product,
    ];
  }

  void _addProduct(Product product) {
    final items = [..._items];
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
        customSubtotal: item.customSubtotal + item.product.price,
      );
    }

    setState(() {
      _items = items;
    });
  }

  void _increaseQuantity(SaleDraftItem item) {
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

  void _decreaseQuantity(SaleDraftItem item) {
    final items = [..._items];
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

    setState(() {
      _items = items;
    });
  }

  void _updateUnitQuantity(SaleDraftItem item, int quantity) {
    if (quantity <= 0) {
      return;
    }

    _updateItem(item, (currentItem) {
      final nextQuantity = quantity.toDouble();
      if (!_hasAvailableStock(currentItem, nextQuantity)) {
        return currentItem;
      }

      return currentItem.copyWith(
        quantity: nextQuantity,
        customSubtotal: currentItem.product.price * nextQuantity,
      );
    });
  }

  void _applyBulkPortion(SaleDraftItem item, AppBulkPortion portion) {
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

  Future<void> _showBulkItemSheet(SaleDraftItem item) async {
    final result = await showModalBottomSheet<BulkSaleItemDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BulkSaleItemSheet(item: item);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    _updateItem(item, (currentItem) {
      if (!_hasAvailableStock(currentItem, result.quantity)) {
        return currentItem;
      }

      return currentItem.copyWith(
        quantity: result.quantity,
        customSubtotal: result.subtotal,
      );
    });
  }

  void _removeItem(SaleDraftItem item) {
    setState(() {
      _items = _items
          .where((currentItem) => currentItem.product.id != item.product.id)
          .toList();
    });
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      _paymentMethod = method;
      if (method != AppPaymentMethods.mixed) {
        _mixedPayments = const {};
      }
    });
  }

  void _updateMixedPayment(String method, double amount) {
    final payments = {..._mixedPayments};

    if (amount <= 0) {
      payments.remove(method);
    } else {
      payments[method] = amount;
    }

    setState(() {
      _mixedPayments = payments;
    });
  }

  void _updateItem(
    SaleDraftItem item,
    SaleDraftItem Function(SaleDraftItem currentItem) update,
  ) {
    final items = [..._items];
    final index = items.indexWhere(
      (currentItem) => currentItem.product.id == item.product.id,
    );

    if (index == -1) {
      return;
    }

    items[index] = update(items[index]);
    setState(() {
      _items = items;
    });
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

  Future<void> _saveChanges() async {
    if (_isSaving || !_canSave) {
      return;
    }

    final shouldSave = await ConfirmDialog.show(
      context,
      title: 'Guardar cambios',
      message:
          'Se actualizará la venta y se ajustarán caja e inventario con los nuevos valores.',
      confirmLabel: 'Guardar',
      icon: Icons.edit_note_rounded,
    );

    if (!mounted || !shouldSave) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final draft = SaleRegisterDraft(
      items: [
        for (final item in _items)
          SaleRegisterItem(
            product: item.product,
            quantity: item.quantity,
            subtotal: item.subtotal,
          ),
      ],
      paymentMethod: _paymentMethod,
      mixedPayments: _mixedPayments,
      commissionRates: _commissionRates,
    );
    final result = await ref
        .read(salesRepositoryProvider)
        .editSale(actor: widget.actor, sale: widget.sale, draft: draft);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (result == SaleEditResult.success) {
      Navigator.of(context).pop(result);
      return;
    }

    Navigator.of(context).pop(result);
  }
}

class _SaleEditTotalCard extends StatelessWidget {
  const _SaleEditTotalCard({
    required this.subtotal,
    required this.commission,
    required this.isSaving,
    required this.canSave,
    required this.onSave,
  });

  final double subtotal;
  final double commission;
  final bool isSaving;
  final bool canSave;
  final VoidCallback onSave;

  double get total => subtotal + commission;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TotalRow(label: 'Subtotal', value: _money(subtotal)),
            const SizedBox(height: AppSpacing.md),
            _TotalRow(label: 'Comisión', value: _money(commission)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderFor(context),
              ),
            ),
            _TotalRow(label: 'Total', value: _money(total), emphasized: true),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: canSave && !isSaving ? onSave : null,
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Guardar cambios'),
                        SizedBox(width: AppSpacing.sm),
                        Icon(Icons.save_rounded),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textStyle = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textStyle?.copyWith(
              color: emphasized
                  ? AppColors.textPrimaryFor(context)
                  : AppColors.textSecondaryFor(context),
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: textStyle?.copyWith(
            color: AppColors.textPrimaryFor(context),
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _initialPaymentMethod(List<SalePayment> payments) {
  if (payments.isEmpty) {
    return AppPaymentMethods.cash;
  }

  if (payments.length == 1) {
    return payments.first.paymentMethod;
  }

  return AppPaymentMethods.mixed;
}

Map<String, double> _initialMixedPayments(List<SalePayment> payments) {
  if (payments.length <= 1) {
    return const {};
  }

  return {
    for (final payment in payments)
      if (payment.baseAmount > 0) payment.paymentMethod: payment.baseAmount,
  };
}

PaymentCommissionRates _initialCommissionRates(
  List<SalePayment> payments,
  PaymentCommissionRates fallbackRates,
) {
  double? terminalCardRate;
  double? terminalBonusRate;

  for (final payment in payments) {
    if (payment.paymentMethod == AppPaymentMethods.terminalCard) {
      terminalCardRate = payment.commissionRate;
    }
    if (payment.paymentMethod == AppPaymentMethods.terminalBonus) {
      terminalBonusRate = payment.commissionRate;
    }
  }

  return PaymentCommissionRates(
    terminalCard: terminalCardRate ?? fallbackRates.terminalCard,
    terminalBonus: terminalBonusRate ?? fallbackRates.terminalBonus,
  );
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}
