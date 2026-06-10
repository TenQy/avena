import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/payment_methods.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_dismiss_area.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../../inventory/providers/inventory_provider.dart';
import '../../data/sales_repository.dart';
import '../../providers/current_sale_provider.dart';
import '../../providers/sales_provider.dart';
import '../models/sale_draft_item.dart';
import '../utils/sale_messages.dart';
import '../widgets/bulk_sale_item_sheet.dart';
import '../widgets/pending_sale_sheet.dart';
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
  bool _isRegistering = false;

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
    final currentSale = ref.watch(currentSaleProvider);
    final saleController = ref.read(currentSaleProvider.notifier);

    ref.listen<AsyncValue<List<Product>>>(productsProvider, (_, next) {
      next.whenData(saleController.syncProducts);
    });

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
              onAddProduct: saleController.addProduct,
            ),
            const SizedBox(height: AppSpacing.lg),
            SaleItemsCard(
              items: currentSale.items,
              onIncreaseQuantity: saleController.increaseQuantity,
              onDecreaseQuantity: saleController.decreaseQuantity,
              onEditBulkItem: _showBulkItemSheet,
              onApplyBulkPortion: saleController.applyBulkPortion,
              onRemoveItem: saleController.removeItem,
            ),
            const SizedBox(height: AppSpacing.lg),
            SalePaymentMethodsCard(
              selectedMethod: currentSale.paymentMethod,
              mixedPayments: currentSale.mixedPayments,
              subtotal: currentSale.subtotal,
              total: currentSale.total,
              mixedTotal: currentSale.mixedTotal,
              commissionRates: currentSale.commissionRates,
              onMethodSelected: saleController.selectPaymentMethod,
              onMixedPaymentChanged: saleController.updateMixedPayment,
            ),
            const SizedBox(height: AppSpacing.lg),
            SaleTotalCard(
              subtotal: currentSale.subtotal,
              commission: currentSale.commission,
              showCashPayment:
                  currentSale.paymentMethod == AppPaymentMethods.cash,
              canRegister: currentSale.canRegister,
              canRegisterPending: currentSale.items.isNotEmpty,
              isRegistering: _isRegistering,
              onRegister: _registerSale,
              onRegisterPending: _registerPendingSale,
            ),
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

    ref
        .read(currentSaleProvider.notifier)
        .updateBulkItem(
          item: item,
          quantity: result.quantity,
          subtotal: result.subtotal,
        );
  }

  Future<void> _registerSale() async {
    if (_isRegistering) {
      return;
    }

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      showSaleRegisterResult(context, SaleRegisterResult.unauthorized);
      return;
    }

    final currentSale = ref.read(currentSaleProvider);
    final draft = SaleRegisterDraft(
      items: [
        for (final item in currentSale.items)
          SaleRegisterItem(
            product: item.product,
            quantity: item.quantity,
            subtotal: item.subtotal,
          ),
      ],
      paymentMethod: currentSale.paymentMethod,
      mixedPayments: currentSale.mixedPayments,
      commissionRates: currentSale.commissionRates,
    );
    final shouldRegister = await ConfirmDialog.show(
      context,
      title: 'Registrar venta',
      message:
          'Se registrará la venta por ${_money(currentSale.total)} y se actualizará caja e inventario.',
      confirmLabel: 'Registrar',
      icon: Icons.point_of_sale_rounded,
    );

    if (!mounted || !shouldRegister) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    final result = await ref
        .read(salesRepositoryProvider)
        .registerSale(actor: currentUser, draft: draft);

    if (!mounted) {
      return;
    }

    setState(() {
      _isRegistering = false;
    });

    if (result == SaleRegisterResult.success) {
      ref.read(currentSaleProvider.notifier).reset();
      _searchController.clear();
    }

    showSaleRegisterResult(context, result);
  }

  Future<void> _registerPendingSale() async {
    if (_isRegistering) {
      return;
    }

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      showSaleRegisterResult(context, SaleRegisterResult.unauthorized);
      return;
    }

    final currentSale = ref.read(currentSaleProvider);
    final draft = SaleRegisterDraft(
      items: [
        for (final item in currentSale.items)
          SaleRegisterItem(
            product: item.product,
            quantity: item.quantity,
            subtotal: item.subtotal,
          ),
      ],
      paymentMethod: currentSale.paymentMethod,
      mixedPayments: currentSale.mixedPayments,
      commissionRates: currentSale.commissionRates,
    );

    final result = await PendingSaleSheet.show(
      context,
      actor: currentUser,
      draft: draft,
      subtotal: currentSale.subtotal,
    );

    if (!mounted || result == null) {
      return;
    }

    if (result == SaleRegisterResult.success) {
      ref.read(currentSaleProvider.notifier).reset();
      _searchController.clear();
    }

    showSaleRegisterResult(context, result);
  }
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}
