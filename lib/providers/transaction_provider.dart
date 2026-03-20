import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Totales
  double get totalIncome {
    return _transactions
        .where((t) => t.type == 'ingreso' && t.isActive)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == 'gasto' && t.isActive)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get netBalance => totalIncome - totalExpense;

  // Transacciones del mes actual
  List<Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      return t.date.month == now.month && 
             t.date.year == now.year && 
             t.isActive;
    }).toList();
  }

  double get currentMonthIncome {
    return currentMonthTransactions
        .where((t) => t.type == 'ingreso')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get currentMonthExpense {
    return currentMonthTransactions
        .where((t) => t.type == 'gasto')
        .fold(0, (sum, t) => sum + t.amount);
  }

  // Cargar transacciones
  Future<void> loadTransactions(String businessRuc) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _transactions = await _databaseService.getAllTransactions(businessRuc);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando transacciones: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear transacción
  Future<bool> addTransaction(Transaction transaction, String businessRuc) async {
    try {
      await _databaseService.createTransaction(transaction);
      await loadTransactions(transaction.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error creando transacción: $e';
      notifyListeners();
      return false;
    }
  }

  // Actualizar transacción
  Future<bool> updateTransaction(Transaction transaction, String businessRuc) async {
    try {
      await _databaseService.updateTransaction(transaction);
      await loadTransactions(transaction.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando transacción: $e';
      notifyListeners();
      return false;
    }
  }

  // Eliminar transacción (soft delete)
  Future<bool> deleteTransaction(int id, String businessRuc) async {
    try {
      await _databaseService.deleteTransactionStatus(id, businessRuc);
      await loadTransactions(businessRuc);
      return true;
    } catch (e) {
      _errorMessage = 'Error eliminando transacción: $e';
      notifyListeners();
      return false;
    }
  }

  // Buscar transacciones
  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;
    
    final lowerQuery = query.toLowerCase();
    return _transactions.where((t) {
      return t.description.toLowerCase().contains(lowerQuery) ||
             t.category.toLowerCase().contains(lowerQuery) ||
             t.type.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Obtener transacciones por mes
  List<Transaction> getTransactionsByMonth(int year, int month) {
    return _transactions.where((t) {
      return t.date.year == year && 
             t.date.month == month && 
             t.isActive;
    }).toList();
  }

  // Categorías disponibles
  List<String> get categories {
    return [
      'alquiler',
      'servicios',
      'sueldos',
      'marketing',
      'transporte',
      'insumos',
      'impuestos',
      'otros'
    ];
  }
}
