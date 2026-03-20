import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../services/database_service.dart';

class ProviderModelProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();

  List<ProviderModel> _providers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<ProviderModel> get providers => _providers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadProviders(String businessRuc) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _providers = await _databaseService.getAllProviders(businessRuc);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando proveedores: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProvider(ProviderModel provider, String businessRuc) async {
    try {
      await _databaseService.createProvider(provider);
      await loadProviders(provider.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error creando proveedor: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProvider(ProviderModel provider, String businessRuc) async {
    try {
      await _databaseService.updateProvider(provider);
      await loadProviders(provider.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando proveedor: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProvider(int id, String businessRuc) async {
    try {
      await _databaseService.deleteProvider(id, businessRuc);
      await loadProviders(businessRuc);
      return true;
    } catch (e) {
      _errorMessage = 'Error eliminando proveedor: $e';
      notifyListeners();
      return false;
    }
  }

  Future<ProviderModel?> getProviderById(int id, String businessRuc) async {
    return await _databaseService.getProviderById(id, businessRuc);
  }

  List<ProviderModel> searchProviders(String query) {
    if (query.isEmpty) return _providers;
    return _providers
        .where((provider) =>
            provider.name.toLowerCase().contains(query.toLowerCase()) ||
            provider.email.toLowerCase().contains(query.toLowerCase()) ||
            provider.phone.contains(query))
        .toList();
  }

  double get totalDebt {
    return _providers.fold(0, (sum, provider) => sum + provider.accountBalance);
  }
}
