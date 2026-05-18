import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';

class InventoryScreenController extends ChangeNotifier {
  Category? _selectedCategory;

  Category? get selectedCategory => _selectedCategory;
  String get title => _selectedCategory?.name ?? 'Inventario';
  bool get canGoBack => _selectedCategory != null;

  void openCategory(Category category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void closeCategory() {
    if (_selectedCategory == null) {
      return;
    }

    _selectedCategory = null;
    notifyListeners();
  }
}
