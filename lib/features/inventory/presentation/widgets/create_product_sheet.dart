import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_products.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/inventory_repository.dart';
import '../../providers/inventory_provider.dart';
import '../utils/number_parser.dart';
import 'inventory_loading_block.dart';
import 'subcategory_dropdown.dart';

class CreateProductSheet extends ConsumerStatefulWidget {
  const CreateProductSheet({super.key, this.initialCategory});

  final Category? initialCategory;

  @override
  ConsumerState<CreateProductSheet> createState() => _CreateProductSheetState();
}

class _CreateProductSheetState extends ConsumerState<CreateProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String _productType = AppProductTypes.unit;
  bool _trackStock = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategory?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final categoriesState = ref.watch(categoriesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: categoriesState.when(
          data: (categories) {
            if (categories.isEmpty) {
              return const EmptyState(
                icon: Icons.category_rounded,
                message: 'Sin categorías aún',
                description: 'Crea una categoría antes de agregar productos.',
              );
            }

            final categoryExists = categories.any(
              (category) => category.id == _selectedCategoryId,
            );
            if (!categoryExists) {
              _selectedCategoryId = null;
              _selectedSubcategoryId = null;
            }

            return Form(
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
                    'Nuevo producto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ProductTextFields(
                    nameController: _nameController,
                    brandController: _brandController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    key: ValueKey('category-$_selectedCategoryId'),
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecciona una categoría.';
                      }

                      return null;
                    },
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCategoryId = value;
                              _selectedSubcategoryId = null;
                            });
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SubcategoryDropdown(
                    categoryId: _selectedCategoryId,
                    selectedSubcategoryId: _selectedSubcategoryId,
                    enabled: !_isSaving,
                    onChanged: (value) {
                      setState(() {
                        _selectedSubcategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProductTypeSelector(
                    productType: _productType,
                    isSaving: _isSaving,
                    onChanged: (value) {
                      setState(() {
                        _productType = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PriceField(
                    controller: _priceController,
                    productType: _productType,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Descripción opcional',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Controlar stock'),
                    value: _trackStock,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _trackStock = value;
                              if (!value) {
                                _stockController.clear();
                              }
                            });
                          },
                  ),
                  if (_trackStock) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _StockField(controller: _stockController),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Crear producto'),
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
            );
          },
          loading: () => const InventoryLoadingBlock(),
          error: (_, _) => const EmptyState(
            icon: Icons.error_outline_rounded,
            message: 'No se pudieron cargar las categorías',
            description: 'Intenta nuevamente.',
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      Navigator.of(context).pop(ProductSaveResult.missingCategory);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(inventoryRepositoryProvider)
        .createProduct(
          ProductDraft(
            name: _nameController.text,
            brand: _brandController.text,
            categoryId: categoryId,
            subcategoryId: _selectedSubcategoryId,
            description: _descriptionController.text,
            productType: _productType,
            price: parseNumber(_priceController.text) ?? 0,
            trackStock: _trackStock,
            stockQuantity: _trackStock
                ? parseNumber(_stockController.text)
                : null,
          ),
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    Navigator.of(context).pop(result);
  }
}

class _ProductTextFields extends StatelessWidget {
  const _ProductTextFields({
    required this.nameController,
    required this.brandController,
  });

  final TextEditingController nameController;
  final TextEditingController brandController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.inventory_2_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa un nombre.';
            }

            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: brandController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Marca opcional',
            prefixIcon: Icon(Icons.sell_rounded),
          ),
        ),
      ],
    );
  }
}

class _ProductTypeSelector extends StatelessWidget {
  const _ProductTypeSelector({
    required this.productType,
    required this.isSaving,
    required this.onChanged,
  });

  final String productType;
  final bool isSaving;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: AppProductTypes.unit,
          label: Text('Unidad'),
          icon: Icon(Icons.inventory_rounded),
        ),
        ButtonSegment(
          value: AppProductTypes.bulk,
          label: Text('Granel'),
          icon: Icon(Icons.scale_rounded),
        ),
      ],
      selected: {productType},
      onSelectionChanged: isSaving ? null : (value) => onChanged(value.first),
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller, required this.productType});

  final TextEditingController controller;
  final String productType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: productType == AppProductTypes.bulk
            ? 'Precio por kilogramo'
            : 'Precio por unidad',
        prefixIcon: const Icon(Icons.attach_money_rounded),
      ),
      validator: (value) {
        final price = parseNumber(value);
        if (price == null || price <= 0) {
          return 'Ingresa un precio válido.';
        }

        return null;
      },
    );
  }
}

class _StockField extends StatelessWidget {
  const _StockField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
      ],
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Stock inicial',
        prefixIcon: Icon(Icons.storage_rounded),
      ),
      validator: (value) {
        final stock = parseNumber(value);
        if (stock == null || stock < 0) {
          return 'Ingresa un stock válido.';
        }

        return null;
      },
    );
  }
}
