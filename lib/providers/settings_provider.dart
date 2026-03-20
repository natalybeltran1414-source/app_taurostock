import 'package:flutter/material.dart';
import '../models/company_settings.dart';
import '../services/database_service.dart';

class SettingsProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  CompanySettings? _settings;
  bool _isLoading = false;

  CompanySettings? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadSettings(String businessRuc) async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _dbService.getSettings(businessRuc);
    } catch (e) {
      print('❌ Error cargando ajustes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(CompanySettings newSettings, String businessRuc) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _dbService.updateSettings(newSettings, businessRuc);
      if (success) {
        _settings = newSettings;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('❌ Error guardando ajustes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
