import 'package:flutter/material.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider({CategoryRepository? repository}) : _repository = repository ?? CategoryRepository();

  final CategoryRepository _repository;
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _repository.getAllCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Category category) async {
    try {
      final exists = await _repository.categoryNameExists(category.name);
      if (exists) {
        return false;
      }

      final id = await _repository.insertCategory(category);
      final createdCategory = category.copyWith(id: id);
      _categories.add(createdCategory);
      _categories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      final exists = await _repository.categoryNameExists(category.name, excludeId: category.id);
      if (exists) {
        return false;
      }

      await _repository.updateCategory(category);
      final index = _categories.indexWhere((item) => item.id == category.id);
      if (index >= 0) {
        _categories[index] = category;
        _categories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final hasProducts = await _repository.hasProducts(id);
      if (hasProducts) {
        return false;
      }

      await _repository.deleteCategory(id);
      _categories.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
