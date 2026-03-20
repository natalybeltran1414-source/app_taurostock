import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class ProductProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();

  List<Product> _products = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadProducts(String businessRuc) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _products = await _databaseService.getAllProducts(businessRuc);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando productos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      final result = await _databaseService.createProduct(product);
      await loadProducts(product.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error creando producto: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _databaseService.updateProduct(product);
      await loadProducts(product.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando producto: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id, String businessRuc) async {
    try {
      await _databaseService.deleteProduct(id, businessRuc);
      await loadProducts(businessRuc);
      return true;
    } catch (e) {
      _errorMessage = 'Error eliminando producto: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Product?> getProductById(int id, String businessRuc) async {
    return await _databaseService.getProductById(id, businessRuc);
  }

  Future<Product?> getProductByBarcode(String barcode, String businessRuc) async {
    return await _databaseService.getProductByBarcode(barcode, businessRuc);
  }

  Future<List<Product>> getLowStockProducts(String businessRuc) async {
    return await _databaseService.getLowStockProducts(businessRuc);
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    return _products
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.barcode.contains(query))
        .toList();
  }

  List<String> get categories {
    final categories = <String>{};
    for (var product in _products) {
      if (product.category.isNotEmpty) {
        categories.add(product.category);
      }
    }
    return categories.toList();
  }
}
