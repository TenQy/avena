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
import '../controllers/inventory_screen_controller.dart';
import '../utils/inventory_messages.dart';
import '../widgets/categories_grid.dart';
import '../widgets/create_category_sheet.dart';
import '../widgets/create_product_sheet.dart';
import '../widgets/inventory_option_tile.dart';
import '../widgets/product_search_field.dart';
import '../widgets/product_search_results.dart';
import 'category_screen.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key, required this.controller});

  final InventoryScreenController controller;

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  final _speedDialController = AppSpeedDialController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant InventoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _speedDialController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final productsState = ref.watch(productsProvider);
    final selectedProduct = widget.controller.selectedProduct;
    final selectedCategory = widget.controller.selectedCategory;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canEditInventory =
        currentUser != null && AppRoles.canEditProducts(currentUser.role);

    if (selectedProduct != null) {
      return ProductDetailScreen(product: selectedProduct);
    }

    if (selectedCategory != null) {
      return InventoryCategoryScreen(
        category: selectedCategory,
        onProductTap: widget.controller.openProduct,
      );
    }

    return Scaffold(
      body: AppDismissArea(
        onDismiss: _speedDialController.close,
        child: categoriesState.when(
          data: (categories) => productsState.when(
            data: (products) => _buildCategories(
              categories: categories,
              products: products,
              canEditInventory: canEditInventory,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const EmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar los productos',
              description: 'Intenta nuevamente.',
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const EmptyState(
            icon: Icons.error_outline_rounded,
            message: 'No se pudieron cargar las categorías',
            description: 'Intenta nuevamente.',
          ),
        ),
      ),
      floatingActionButton: canEditInventory
          ? SnackBarAwareFab(
              child: AppSpeedDialFab(
                controller: _speedDialController,
                actions: [
                  AppSpeedDialAction(
                    icon: Icons.category_rounded,
                    label: 'Crear categoría',
                    onPressed: _showCreateCategoryForm,
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

  Widget _buildCategories({
    required List<Category> categories,
    required List<Product> products,
    required bool canEditInventory,
  }) {
    final searchQuery = _searchController.text;

    return CustomScrollView(
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
        if (searchQuery.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                104,
              ),
              child: ProductSearchResults(
                products: products,
                query: searchQuery,
              ),
            ),
          )
        else if (categories.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.category_rounded,
              message: 'Sin categorías aún',
              description: 'Toca + para agregar una.',
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                104,
              ),
              child: CategoriesGrid(
                categories: categories,
                onCategoryTap: _openCategory,
                onCategoryLongPress: canEditInventory
                    ? _showCategoryActions
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  void _openCategory(Category category) {
    widget.controller.openCategory(category);
  }

  Future<void> _showCreateProductForm() async {
    final result = await showModalBottomSheet<ProductSaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const CreateProductSheet();
      },
    );

    if (!mounted || result == null) {
      return;
    }

    showProductSaveResult(context, result);
  }

  Future<void> _showCreateCategoryForm() async {
    final result = await showModalBottomSheet<CategorySaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const CreateCategorySheet();
      },
    );

    if (!mounted || result == null) {
      return;
    }

    showCategorySaveResult(context, result);
  }

  Future<void> _showCategoryActions(Category category) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardSurface,
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                InventoryOptionTile(
                  icon: Icons.star_rounded,
                  label: 'Establecer como principal',
                  onTap: () {
                    Navigator.of(context).pop();
                    _setMainCategory(category);
                  },
                ),
                InventoryOptionTile(
                  icon: Icons.delete_rounded,
                  label: 'Eliminar categoría',
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteCategory(category);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setMainCategory(Category category) async {
    final result = await ref
        .read(inventoryRepositoryProvider)
        .setMainCategory(category);

    if (!mounted) {
      return;
    }

    showCategoryActionResult(
      context,
      result,
      successMessage: 'Categoría principal actualizada.',
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final shouldDelete = await ConfirmDialog.show(
      context,
      title: 'Eliminar categoría',
      message: 'La categoría se quitará del inventario si no tiene productos.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_rounded,
    );

    if (!mounted || !shouldDelete) {
      return;
    }

    final result = await ref
        .read(inventoryRepositoryProvider)
        .deleteCategory(category);

    if (!mounted) {
      return;
    }

    showCategoryActionResult(
      context,
      result,
      successMessage: 'Categoría eliminada.',
    );
  }
}
