import 'package:flutter/material.dart';
import '../models/purchase.dart';
import '../services/database_service.dart';

class PurchaseProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();

  List<Purchase> _purchases = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // ← CORREGIDO: Total de compras PAGADAS (para resumen financiero)
  double get totalPurchases {
    return _purchases
        .where((p) => p.paymentStatus == 'pagado')
        .fold<double>(0, (sum, purchase) => sum + purchase.finalAmount);
  }

  // ← NUEVO: Total de compras PENDIENTES (para deudas)
  double get totalPendingPurchases {
    return _purchases
        .where((p) => p.paymentStatus == 'pendiente')
        .fold<double>(0, (sum, purchase) => sum + purchase.finalAmount);
  }

  // ← NUEVO: Obtener compras pagadas (para Dashboard/Ingresos)
  List<Purchase> get paidPurchases {
    return _purchases.where((p) => p.paymentStatus == 'pagado').toList();
  }

  // ← NUEVO: Obtener compras pendientes (para Deudas)
  List<Purchase> get pendingPurchases {
    return _purchases.where((p) => p.paymentStatus == 'pendiente').toList();
  }

  Future<void> loadPurchases() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _purchases = await _databaseService.getAllPurchases();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando compras: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPurchase(Purchase purchase) async {
    try {
      await _databaseService.createPurchase(purchase);
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Error registrando compra: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsPaid(int purchaseId) async {
    try {
      await _databaseService.updatePurchasePaymentStatus(purchaseId, 'pagado');
      await loadPurchases();
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando pago: $e';
      notifyListeners();
      return false;
    }
  }

  List<Purchase> searchPurchases(String query) {
    if (query.isEmpty) return _purchases;
    return _purchases.where((purchase) {
      return purchase.providerId.toString().contains(query) ||
          purchase.paymentStatus.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}