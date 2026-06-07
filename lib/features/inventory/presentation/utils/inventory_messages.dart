import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../data/inventory_repository.dart';

void showCategorySaveResult(BuildContext context, CategorySaveResult result) {
  final message = switch (result) {
    CategorySaveResult.success => 'Categoria creada.',
    CategorySaveResult.emptyName => 'Ingresa un nombre de categoria.',
    CategorySaveResult.nameTaken => 'Esa categoria ya existe.',
  };

  showAppSnackBar(context, message);
}

void showCategoryActionResult(
  BuildContext context,
  CategoryActionResult result, {
  required String successMessage,
}) {
  final message = switch (result) {
    CategoryActionResult.success => successMessage,
    CategoryActionResult.hasProducts =>
      'No se puede eliminar una categoria con productos.',
    CategoryActionResult.notFound => 'La categoria ya no existe.',
  };

  showAppSnackBar(context, message);
}

void showSubcategorySaveResult(
  BuildContext context,
  SubcategorySaveResult result,
) {
  final message = switch (result) {
    SubcategorySaveResult.success => 'Subcategoria creada.',
    SubcategorySaveResult.emptyName => 'Ingresa un nombre de subcategoria.',
    SubcategorySaveResult.nameTaken => 'Esa subcategoria ya existe.',
    SubcategorySaveResult.categoryNotFound => 'La categoria ya no existe.',
  };

  showAppSnackBar(context, message);
}

void showSubcategoryActionResult(
  BuildContext context,
  SubcategoryActionResult result,
) {
  final message = switch (result) {
    SubcategoryActionResult.success => 'Subcategoria eliminada.',
    SubcategoryActionResult.notFound => 'La subcategoria ya no existe.',
  };

  showAppSnackBar(context, message);
}

void showProductSaveResult(
  BuildContext context,
  ProductSaveResult result, {
  String successMessage = 'Producto creado.',
}) {
  final message = switch (result) {
    ProductSaveResult.success => successMessage,
    ProductSaveResult.emptyName => 'Ingresa un nombre de producto.',
    ProductSaveResult.missingCategory => 'Selecciona una categoria.',
    ProductSaveResult.invalidPrice => 'Ingresa un precio valido.',
    ProductSaveResult.invalidCost => 'Ingresa un costo valido.',
    ProductSaveResult.invalidStock => 'Ingresa un stock valido.',
    ProductSaveResult.categoryNotFound => 'La categoria ya no existe.',
    ProductSaveResult.subcategoryNotFound => 'La subcategoria ya no existe.',
  };

  showAppSnackBar(context, message);
}

void showProductActionResult(
  BuildContext context,
  ProductActionResult result, {
  required String successMessage,
}) {
  final message = switch (result) {
    ProductActionResult.success => successMessage,
    ProductActionResult.notFound => 'El producto ya no existe.',
  };

  showAppSnackBar(context, message);
}
