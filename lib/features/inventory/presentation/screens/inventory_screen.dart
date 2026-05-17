import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/app_speed_dial_fab.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/inventory_repository.dart';
import '../../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      body: categoriesState.when(
        data: (categories) {
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
                  child: _ProductSearchField(controller: _searchController),
                ),
              ),
              if (categories.isEmpty)
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
                    child: _CategoriesGrid(
                      categories: categories,
                      onCategoryLongPress: _showCategoryActions,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline_rounded,
          message: 'No se pudieron cargar las categorías',
          description: 'Intenta nuevamente.',
        ),
      ),
      floatingActionButton: SnackBarAwareFab(
        child: AppSpeedDialFab(
          actions: [
            AppSpeedDialAction(
              icon: Icons.category_rounded,
              label: 'Crear categoría',
              onPressed: _showCreateCategoryForm,
            ),
            AppSpeedDialAction(
              icon: Icons.inventory_2_rounded,
              label: 'Crear producto',
              onPressed: _showCreateProductPendingMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateProductPendingMessage() {
    showAppSnackBar(context, 'Crear producto estará disponible pronto.');
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
        return const _CreateCategorySheet();
      },
    );

    if (!mounted || result == null) {
      return;
    }

    _showCategorySaveResult(result);
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
                _InventoryOptionTile(
                  icon: Icons.star_rounded,
                  label: 'Establecer como principal',
                  onTap: () {
                    Navigator.of(context).pop();
                    _setMainCategory(category);
                  },
                ),
                _InventoryOptionTile(
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

    _showCategoryActionResult(
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

    _showCategoryActionResult(result, successMessage: 'Categoría eliminada.');
  }

  void _showCategorySaveResult(CategorySaveResult result) {
    final message = switch (result) {
      CategorySaveResult.success => 'Categoría creada.',
      CategorySaveResult.emptyName => 'Ingresa un nombre de categoría.',
      CategorySaveResult.nameTaken => 'Esa categoría ya existe.',
    };

    showAppSnackBar(context, message);
  }

  void _showCategoryActionResult(
    CategoryActionResult result, {
    required String successMessage,
  }) {
    final message = switch (result) {
      CategoryActionResult.success => successMessage,
      CategoryActionResult.hasProducts =>
        'No se puede eliminar una categoría con productos.',
      CategoryActionResult.notFound => 'La categoría ya no existe.',
    };

    showAppSnackBar(context, message);
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({
    required this.categories,
    required this.onCategoryLongPress,
  });

  final List<Category> categories;
  final ValueChanged<Category> onCategoryLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        final itemHeight = itemWidth / 1.35;

        return Column(
          children: [
            SizedBox(
              height: itemHeight,
              child: _CategoryCard(
                category: categories.first,
                isMain: true,
                onLongPress: () => onCategoryLongPress(categories.first),
              ),
            ),
            if (categories.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length - 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index + 1];

                  return _CategoryCard(
                    category: category,
                    isMain: false,
                    onLongPress: () => onCategoryLongPress(category),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ProductSearchField extends StatelessWidget {
  const _ProductSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar producto...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) {
              return const SizedBox.shrink();
            }

            return IconButton(
              tooltip: 'Limpiar búsqueda',
              icon: const Icon(Icons.close_rounded),
              onPressed: controller.clear,
            );
          },
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isMain,
    required this.onLongPress,
  });

  final Category category;
  final bool isMain;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.headerNav,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Icon(
                  _categoryIcon(category.name),
                  color: AppColors.iconInactive,
                  size: isMain ? 36 : 32,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                category.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryOptionTile extends StatelessWidget {
  const _InventoryOptionTile({
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
          color: AppColors.bodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, color: AppColors.iconInactive, size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.iconInactive,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}

class _CreateCategorySheet extends ConsumerStatefulWidget {
  const _CreateCategorySheet();

  @override
  ConsumerState<_CreateCategorySheet> createState() =>
      _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<_CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Nueva categoría',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, thickness: 0.5, color: AppColors.border),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nombre de categoría',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre.';
                  }

                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Crear categoría'),
                    const SizedBox(width: AppSpacing.sm),
                    if (_isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.save_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(inventoryRepositoryProvider)
        .createCategory(_nameController.text);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (result == CategorySaveResult.success) {
      Navigator.of(context).pop(result);
      return;
    }

    Navigator.of(context).pop(result);
  }
}

IconData _categoryIcon(String name) {
  final value = name.toLowerCase();

  if (value.contains('alimento') ||
      value.contains('mascota') ||
      value.contains('perro') ||
      value.contains('gato')) {
    return Icons.pets_rounded;
  }

  if (value.contains('granel')) {
    return Icons.scale_rounded;
  }

  if (value.contains('dulce') ||
      value.contains('candy') ||
      value.contains('golosina')) {
    return Icons.cookie_rounded;
  }

  if (value.contains('especia') ||
      value.contains('chile') ||
      value.contains('hierba') ||
      value.contains('condimento')) {
    return Icons.grass_rounded;
  }

  if (value.contains('abarrote') || value.contains('basico')) {
    return Icons.shopping_basket_rounded;
  }

  if (value.contains('combustible') ||
      value.contains('carbon') ||
      value.contains('lena')) {
    return Icons.local_fire_department_rounded;
  }

  return Icons.category_rounded;
}
