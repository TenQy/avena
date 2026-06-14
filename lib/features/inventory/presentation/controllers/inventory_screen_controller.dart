import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class InventoryScreenController extends ChangeNotifier {
  Category? _selectedCategory;
  Product? _selectedProduct;

  Category? get selectedCategory => _selectedCategory;
  Product? get selectedProduct => _selectedProduct;
  String get title =>
      _selectedProduct?.name ?? _selectedCategory?.name ?? 'Inventario';
  bool get canGoBack => _selectedCategory != null || _selectedProduct != null;

  void openCategory(Category category) {
    _selectedCategory = category;
    _selectedProduct = null;
    notifyListeners();
  }

  void syncSelectedCategory(Category category) {
    if (_selectedCategory?.id != category.id) {
      return;
    }

    _selectedCategory = category;
    notifyListeners();
  }

  void openProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void closeCategory() {
    if (_selectedProduct != null) {
      _selectedProduct = null;
      notifyListeners();
      return;
    }

    if (_selectedCategory == null) {
      return;
    }

    _selectedCategory = null;
    notifyListeners();
  }
}
