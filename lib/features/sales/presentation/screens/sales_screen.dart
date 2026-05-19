import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_dismiss_area.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../inventory/providers/inventory_provider.dart';
import '../models/sale_draft_item.dart';
import '../widgets/bulk_sale_item_sheet.dart';
import '../widgets/sale_items_card.dart';
import '../widgets/sale_payment_methods_card.dart';
import '../widgets/sale_product_search_card.dart';
import '../widgets/sale_total_card.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _searchController = TextEditingController();
  final List<SaleDraftItem> _items = [];

  double get _subtotal {
    return _items.fold(0, (total, item) => total + item.subtotal);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);

    return AppDismissArea(
      child: productsState.when(
        data: (products) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            SaleProductSearchCard(
              controller: _searchController,
              products: products,
              query: _searchController.text,
              onAddProduct: _addProduct,
            ),
            const SizedBox(height: AppSpacing.lg),
            SaleItemsCard(
              items: _items,
              onIncreaseQuantity: _increaseQuantity,
              onDecreaseQuantity: _decreaseQuantity,
              onEditBulkItem: _showBulkItemSheet,
              onRemoveItem: _removeItem,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SalePaymentMethodsCard(),
            const SizedBox(height: AppSpacing.lg),
            SaleTotalCard(subtotal: _subtotal, commission: 0),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline_rounded,
          message: 'No se pudieron cargar los productos',
          description: 'Intenta nuevamente.',
        ),
      ),
    );
  }

  void _addProduct(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    setState(() {
      if (index == -1) {
        _items.add(SaleDraftItem(product: product, quantity: 1));
        return;
      }

      final item = _items[index];
      _items[index] = item.copyWith(quantity: item.quantity + 1);
    });
  }

  Future<void> _showBulkItemSheet(SaleDraftItem item) async {
    final result = await showModalBottomSheet<BulkSaleItemDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
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

    final index = _items.indexWhere(
      (currentItem) => currentItem.product.id == item.product.id,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      _items[index] = _items[index].copyWith(
        quantity: result.quantity,
        customSubtotal: result.subtotal,
      );
    });
  }

  void _increaseQuantity(SaleDraftItem item) {
    final index = _items.indexWhere(
      (currentItem) => currentItem.product.id == item.product.id,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
    });
  }

  void _decreaseQuantity(SaleDraftItem item) {
    final index = _items.indexWhere(
      (currentItem) => currentItem.product.id == item.product.id,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      final nextQuantity = _items[index].quantity - 1;
      if (nextQuantity <= 0) {
        _items.removeAt(index);
        return;
      }

      _items[index] = _items[index].copyWith(quantity: nextQuantity);
    });
  }

  void _removeItem(SaleDraftItem item) {
    setState(() {
      _items.removeWhere(
        (currentItem) => currentItem.product.id == item.product.id,
      );
    });
  }
}
