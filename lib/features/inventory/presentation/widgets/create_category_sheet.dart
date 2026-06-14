import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../data/inventory_repository.dart';
import '../../providers/inventory_provider.dart';

class CreateCategorySheet extends ConsumerStatefulWidget {
  const CreateCategorySheet({super.key, this.category});

  final Category? category;

  @override
  ConsumerState<CreateCategorySheet> createState() =>
      _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category?.name ?? '';
  }

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
                    color: AppColors.borderFor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _isEditing ? 'Editar categoria' : 'Nueva categoría',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderFor(context),
              ),
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
                    Text(_isEditing ? 'Guardar cambios' : 'Crear categoría'),
                    const SizedBox(width: AppSpacing.sm),
                    if (_isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.save_rounded),
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

    final actor = ref.read(currentUserProvider).valueOrNull;
    if (actor == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      Navigator.of(context).pop(CategorySaveResult.notFound);
      return;
    }

    final repository = ref.read(inventoryRepositoryProvider);
    final category = widget.category;
    final result = category == null
        ? await repository.createCategory(
            actor: actor,
            name: _nameController.text,
          )
        : await repository.updateCategory(
            actor: actor,
            category: category,
            name: _nameController.text,
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
