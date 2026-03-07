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

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _products = await _databaseService.getAllProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando productos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    // ========== LOGS DE DEPURACIÓN ==========
    print('📦 PRODUCT_PROVIDER.addProduct - INICIO');
    print('📦 Producto recibido: ${product.name}');
    print('📦 ID: ${product.id}');
    // ========================================
    
    try {
      // ========== LOG ==========
      print('💾 Llamando a databaseService.createProduct...');
      // =========================
      
      final result = await _databaseService.createProduct(product);
      
      // ========== LOGS ==========
      print('✅ databaseService.createProduct completado');
      print('📦 Resultado: $result');
      print('🔄 Recargando productos...');
      // =========================
      
      await loadProducts();
      
      // ========== LOG ==========
      print('✅ Productos recargados');
      print('✅ addProduct completado exitosamente');
      // =========================
      
      return true;
    } catch (e) {
      // ========== LOG ==========
      print('🔥 ERROR en addProduct: $e');
      // =========================
      
      _errorMessage = 'Error creando producto: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _databaseService.updateProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando producto: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _databaseService.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Error eliminando producto: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Product?> getProductById(int id) async {
    return await _databaseService.getProductById(id);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    return await _databaseService.getProductByBarcode(barcode);
  }

  Future<List<Product>> getLowStockProducts() async {
    return await _databaseService.getLowStockProducts();
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