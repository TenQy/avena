import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_dismiss_area.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/app_speed_dial_fab.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/inventory_repository.dart';
import '../../providers/inventory_provider.dart';
import '../utils/inventory_messages.dart';
import '../widgets/category_product_list.dart';
import '../widgets/create_product_sheet.dart';
import '../widgets/create_subcategory_sheet.dart';
import '../widgets/inventory_loading_block.dart';
import '../widgets/product_search_field.dart';

class InventoryCategoryScreen extends ConsumerStatefulWidget {
  const InventoryCategoryScreen({super.key, required this.category});

  final Category category;

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
                        onDeleteSubcategory: _deleteSubcategory,
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
      floatingActionButton: SnackBarAwareFab(
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
      ),
    );
  }

  Future<void> _showCreateSubcategoryForm() async {
    final result = await showModalBottomSheet<SubcategorySaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
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
      backgroundColor: AppColors.cardSurface,
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

  void _setSubcategoryFilter(String? subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });
  }

  Future<void> _deleteSubcategory(Subcategory subcategory) async {
    final shouldDelete = await ConfirmDialog.show(
      context,
      title: 'Eliminar subcategoría',
      message:
          'La subcategoría se quitará y sus productos pasarán a Sin subcategoría.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_rounded,
    );

    if (!mounted || !shouldDelete) {
      return;
    }

    final result = await ref
        .read(inventoryRepositoryProvider)
        .deleteSubcategory(subcategory);

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
}
