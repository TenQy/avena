import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_dismiss_area.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/app_speed_dial_fab.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../data/inventory_repository.dart';
import '../../providers/inventory_provider.dart';
import '../utils/inventory_messages.dart';
import '../widgets/category_product_list.dart';
import '../widgets/create_product_sheet.dart';
import '../widgets/create_subcategory_sheet.dart';
import '../widgets/inventory_loading_block.dart';
import '../widgets/product_search_field.dart';

class InventoryCategoryScreen extends ConsumerStatefulWidget {
  const InventoryCategoryScreen({
    super.key,
    required this.category,
    required this.onProductTap,
  });

  final Category category;
  final ValueChanged<Product> onProductTap;

  @override
  ConsumerState<InventoryCategoryScreen> createState() =>
      _InventoryCategoryScreenState();
}

class _InventoryCategoryScreenState
    extends ConsumerState<InventoryCategoryScreen> {
  final _searchController = TextEditingController();
  final _speedDialController = AppSpeedDialController();
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _speedDialController.dispose();
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
    final subcategoriesState = ref.watch(
      subcategoriesByCategoryProvider(widget.category.id),
    );
    final productsState = ref.watch(
      productsByCategoryProvider(widget.category.id),
    );
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canEditInventory =
        currentUser != null && AppRoles.canEditProducts(currentUser.role);

    return Scaffold(
      body: AppDismissArea(
        onDismiss: _speedDialController.close,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: ProductSearchField(controller: _searchController),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                104,
              ),
              sliver: SliverToBoxAdapter(
                child: subcategoriesState.when(
                  data: (subcategories) {
                    return productsState.when(
                      data: (products) => CategoryProductList(
                        subcategories: subcategories,
                        products: products,
                        searchQuery: _searchController.text,
                        selectedSubcategoryId: _selectedSubcategoryId,
                        onFilterChanged: _setSubcategoryFilter,
                        onProductTap: _openProductDetail,
                        onDeleteSubcategory: canEditInventory
                            ? _deleteSubcategory
                            : null,
                        onProductLongPress: canEditInventory
                            ? _showProductActions
                            : null,
                      ),
                      loading: () => const InventoryLoadingBlock(),
                      error: (_, _) => const EmptyState(
                        icon: Icons.error_outline_rounded,
                        message: 'No se pudieron cargar los productos',
                        description: 'Intenta nuevamente.',
                      ),
                    );
                  },
                  loading: () => const InventoryLoadingBlock(),
                  error: (_, _) => const EmptyState(
                    icon: Icons.error_outline_rounded,
                    message: 'No se pudieron cargar las subcategorías',
                    description: 'Intenta nuevamente.',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canEditInventory
          ? SnackBarAwareFab(
              child: AppSpeedDialFab(
                controller: _speedDialController,
                actions: [
                  AppSpeedDialAction(
                    icon: Icons.create_new_folder_rounded,
                    label: 'Crear subcategoría',
                    onPressed: _showCreateSubcategoryForm,
                  ),
                  AppSpeedDialAction(
                    icon: Icons.inventory_2_rounded,
                    label: 'Crear producto',
                    onPressed: _showCreateProductForm,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _showCreateSubcategoryForm() async {
    final result = await showModalBottomSheet<SubcategorySaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CreateSubcategorySheet(category: widget.category);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    showSubcategorySaveResult(context, result);
  }

  Future<void> _showCreateProductForm() async {
    final result = await showModalBottomSheet<ProductSaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CreateProductSheet(initialCategory: widget.category);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    showProductSaveResult(context, result);
  }

  Future<void> _showEditProductForm(Product product) async {
    final result = await showModalBottomSheet<ProductSaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CreateProductSheet(product: product);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    showProductSaveResult(
      context,
      result,
      successMessage: 'Producto actualizado.',
    );
  }

  Future<void> _showProductActions(Product product) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderFor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ProductActionTile(
                  icon: Icons.edit_rounded,
                  label: 'Editar producto',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showEditProductForm(product);
                  },
                ),
                _ProductActionTile(
                  icon: Icons.delete_rounded,
                  label: 'Eliminar producto',
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteProduct(product);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setSubcategoryFilter(String? subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });
  }

  void _openProductDetail(Product product) {
    widget.onProductTap(product);
  }

  Future<void> _deleteSubcategory(Subcategory subcategory) async {
    final shouldDelete = await ConfirmDialog.show(
      context,
      title: 'Eliminar subcategoría',
      message: 'La subcategoría se quitará y sus productos pasarán a Otros.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_rounded,
    );

    if (!mounted || !shouldDelete) {
      return;
    }

    final actor = ref.read(currentUserProvider).valueOrNull;
    if (actor == null) {
      return;
    }

    final result = await ref
        .read(inventoryRepositoryProvider)
        .deleteSubcategory(actor, subcategory);

    if (!mounted) {
      return;
    }

    if (_selectedSubcategoryId == subcategory.id) {
      setState(() {
        _selectedSubcategoryId = null;
      });
    }

    showSubcategoryActionResult(context, result);
  }

  Future<void> _deleteProduct(Product product) async {
    final shouldDelete = await ConfirmDialog.show(
      context,
      title: 'Eliminar producto',
      message: 'El producto se quitará del inventario.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_rounded,
    );

    if (!mounted || !shouldDelete) {
      return;
    }

    final actor = ref.read(currentUserProvider).valueOrNull;
    if (actor == null) {
      return;
    }

    final result = await ref
        .read(inventoryRepositoryProvider)
        .deleteProduct(actor: actor, product: product);

    if (!mounted) {
      return;
    }

    showProductActionResult(
      context,
      result,
      successMessage: 'Producto eliminado.',
    );
  }
}

class _ProductActionTile extends StatelessWidget {
  const _ProductActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bodyBgFor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderFor(context), width: 0.5),
        ),
        child: Icon(icon, color: AppColors.iconInactiveFor(context), size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.iconInactiveFor(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}
