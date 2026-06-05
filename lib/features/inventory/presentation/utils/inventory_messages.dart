import 'package:flutter/material.dart';

import '../../data/inventory_repository.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

void showCategorySaveResult(BuildContext context, CategorySaveResult result) {
  final message = switch (result) {
    CategorySaveResult.success => 'CategorÃƒÂ­a creada.',
    CategorySaveResult.emptyName => 'Ingresa un nombre de categorÃƒÂ­a.',
    CategorySaveResult.nameTaken => 'Esa categorÃƒÂ­a ya existe.',
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
      'No se puede eliminar una categorÃƒÂ­a con productos.',
    CategoryActionResult.notFound => 'La categorÃƒÂ­a ya no existe.',
  };

  showAppSnackBar(context, message);
}

void showSubcategorySaveResult(
  BuildContext context,
  SubcategorySaveResult result,
) {
  final message = switch (result) {
    SubcategorySaveResult.success => 'SubcategorÃƒÂ­a creada.',
    SubcategorySaveResult.emptyName => 'Ingresa un nombre de subcategorÃƒÂ­a.',
    SubcategorySaveResult.nameTaken => 'Esa subcategorÃƒÂ­a ya existe.',
    SubcategorySaveResult.categoryNotFound => 'La categorÃƒÂ­a ya no existe.',
  };

  showAppSnackBar(context, message);
}

void showSubcategoryActionResult(
  BuildContext context,
  SubcategoryActionResult result,
) {
  final message = switch (result) {
    SubcategoryActionResult.success => 'SubcategorÃƒÂ­a eliminada.',
    SubcategoryActionResult.notFound => 'La subcategorÃƒÂ­a ya no existe.',
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
    ProductSaveResult.missingCategory => 'Selecciona una categorÃƒÂ­a.',
    ProductSaveResult.invalidPrice => 'Ingresa un precio vÃƒÂ¡lido.',
    ProductSaveResult.invalidStock => 'Ingresa un stock vÃƒÂ¡lido.',
    ProductSaveResult.categoryNotFound => 'La categorÃƒÂ­a ya no existe.',
    ProductSaveResult.subcategoryNotFound => 'La subcategorÃƒÂ­a ya no existe.',
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
