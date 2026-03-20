import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadCategories(String businessRuc) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _categories = await _databaseService.getAllCategories(businessRuc);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando categorías: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(Category category, String businessRuc) async {
    try {
      await _databaseService.createCategory(category);
      await loadCategories(category.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error creando categoría: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category, String businessRuc) async {
    try {
      final success = await _databaseService.updateCategory(category);
      if (success) {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = category;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
    }
    return false;
  }

  Future<bool> deleteCategory(int id, String businessRuc) async {
    try {
      await _databaseService.deleteCategory(id, businessRuc);
      await loadCategories(businessRuc);
      return true;
    } catch (e) {
      _errorMessage = 'Error eliminando categoría: $e';
      notifyListeners();
      return false;
    }
  }
}
