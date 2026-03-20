import 'package:flutter/material.dart';
import '../models/cash_session.dart';
import '../services/database_service.dart';

class CashProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  CashSession? _currentSession;
  bool _isLoading = false;
  String _errorMessage = '';

  CashSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  bool get isSessionOpen => _currentSession != null && _currentSession!.status == 'open';
  String get errorMessage => _errorMessage;

  Future<void> checkActiveSession(String businessRuc) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentSession = await _dbService.getCurrentCashSession(businessRuc);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error verificando sesión de caja: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> openSession(double amount, int userId, String businessRuc) async {
    try {
      final session = CashSession(
        openingAmount: amount,
        openingDate: DateTime.now(),
        userId: userId,
        status: 'open',
        businessRuc: businessRuc,
      );
      await _dbService.openCashSession(session);
      await checkActiveSession(businessRuc);
      return true;
    } catch (e) {
      _errorMessage = 'Error abriendo sesión: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeSession(double amount, String businessRuc) async {
    if (_currentSession == null) return false;
    try {
      final success = await _dbService.closeCashSession(_currentSession!.id!, amount, businessRuc);
      if (success) {
        await checkActiveSession(businessRuc);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error cerrando sesión: $e';
      notifyListeners();
      return false;
    }
  }
}
