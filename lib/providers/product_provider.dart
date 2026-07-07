import 'package:flutter/material.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductRepository? repository}) : _repository = repository ?? ProductRepository();

  final ProductRepository _repository;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _repository.getAllProducts();
      _applyFilter();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      final exists = await _repository.productExists(
        categoryId: product.categoryId,
        brand: product.brand,
        name: product.name,
      );
      if (exists) {
        return false;
      }

      final id = await _repository.insertProduct(product);
      final createdProduct = product.copyWith(id: id);
      _products.add(createdProduct);
      _products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _applyFilter();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final exists = await _repository.productExists(
        categoryId: product.categoryId,
        brand: product.brand,
        name: product.name,
        excludeId: product.id,
      );
      if (exists) {
        return false;
      }

      await _repository.updateProduct(product);
      final index = _products.indexWhere((item) => item.id == product.id);
      if (index >= 0) {
        _products[index] = product;
        _products.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _applyFilter();
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _repository.deleteProduct(id);
      _products.removeWhere((item) => item.id == id);
      _applyFilter();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void search(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
      return;
    }

    _filteredProducts = _products.where((product) {
      final name = product.name.toLowerCase();
      final brand = product.brand.toLowerCase();
      return name.contains(_searchQuery) || brand.contains(_searchQuery);
    }).toList();
  }
}
