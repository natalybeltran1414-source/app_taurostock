import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../services/database_service.dart';

class SaleProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();

  List<Sale> _sales = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // ← CORREGIDO: Total de ventas PAGADAS (para resumen financiero)
  double get totalSales {
    return _sales
        .where((s) => s.status == 'completada' && s.paymentMethod != 'credito')
        .fold<double>(0, (sum, sale) => sum + sale.finalAmount);
  }

  // ← NUEVO: Total de ventas a CRÉDITO (para deudas)
  double get totalCreditSales {
    return _sales
        .where((s) => s.paymentMethod == 'credito' && s.status == 'pendiente')
        .fold<double>(0, (sum, sale) => sum + sale.finalAmount);
  }

  // ← CORREGIDO: Obtener ventas de los últimos 7 días (SOLO PAGADAS)
  List<Sale> get last7DaysSales {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    return _sales.where((sale) {
      return sale.saleDate.isAfter(sevenDaysAgo) && 
             sale.saleDate.isBefore(now) &&
             sale.status == 'completada' &&
             sale.paymentMethod != 'credito';
    }).toList();
  }

  // ← CORREGIDO: Ventas por día (últimos 7 días) - SOLO PAGADAS
  Map<String, double> get salesByDay {
    final Map<String, double> result = {};
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.day}/${date.month}';
      
      final daySales = _sales.where((sale) {
        return sale.saleDate.day == date.day &&
               sale.saleDate.month == date.month &&
               sale.saleDate.year == date.year &&
               sale.status == 'completada' &&
               sale.paymentMethod != 'credito';
      }).toList();
      
      final total = daySales.fold<double>(
        0, (sum, sale) => sum + sale.finalAmount
      );
      
      result[dateStr] = total;
    }
    
    return result;
  }

  // ← CORREGIDO: Top 5 productos más vendidos (SOLO DE VENTAS PAGADAS)
  List<Map<String, dynamic>> get topProducts {
    final Map<int, Map<String, dynamic>> productMap = {};
    
    for (var sale in _sales) {
      if (sale.status == 'completada' && sale.paymentMethod != 'credito') {
        for (var item in sale.items) {
          if (productMap.containsKey(item.productId)) {
            productMap[item.productId]!['quantity'] += item.quantity;
            productMap[item.productId]!['total'] += item.totalPrice;
          } else {
            productMap[item.productId] = {
              'id': item.productId,
              'name': item.productName,
              'quantity': item.quantity,
              'total': item.totalPrice,
            };
          }
        }
      }
    }
    
    final List<Map<String, dynamic>> productList = productMap.values.toList();
    productList.sort((a, b) => b['quantity'].compareTo(a['quantity']));
    
    return productList.take(5).toList();
  }

  // ← CORREGIDO: Ventas totales de hoy (SOLO PAGADAS)
  double get todaySales {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _sales.where((sale) {
      return sale.saleDate.isAfter(today) && 
             sale.status == 'completada' &&
             sale.paymentMethod != 'credito';
    }).fold<double>(0, (sum, sale) => sum + sale.finalAmount);
  }

  // ← CORREGIDO: Ventas totales de ayer (SOLO PAGADAS)
  double get yesterdaySales {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfYesterday = startOfYesterday.add(const Duration(days: 1));
    
    return _sales.where((sale) {
      return sale.saleDate.isAfter(startOfYesterday) && 
             sale.saleDate.isBefore(endOfYesterday) &&
             sale.status == 'completada' &&
             sale.paymentMethod != 'credito';
    }).fold<double>(0, (sum, sale) => sum + sale.finalAmount);
  }

  // Porcentaje de cambio vs ayer (usa todaySales y yesterdaySales, que ya filtran)
  double get changePercentage {
    final today = todaySales;
    final yesterday = yesterdaySales;
    
    if (yesterday == 0) return today > 0 ? 100 : 0;
    return ((today - yesterday) / yesterday) * 100;
  }

  // ← CORREGIDO: Total de productos vendidos hoy (SOLO DE VENTAS PAGADAS)
  int get todayProductsCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todaySalesList = _sales.where((sale) {
      return sale.saleDate.isAfter(today) && 
             sale.status == 'completada' &&
             sale.paymentMethod != 'credito';
    }).toList();
    
    int count = 0;
    for (var sale in todaySalesList) {
      for (var item in sale.items) {
        count += item.quantity;
      }
    }
    
    return count;
  }

  // Cargar todas las ventas (sin cambios - carga todo)
  Future<void> loadSales() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _sales = await _databaseService.getAllSales();
      
      for (int i = 0; i < _sales.length; i++) {
        final saleWithItems = await _databaseService.getSaleById(_sales[i].id!);
        if (saleWithItems != null) {
          _sales[i] = saleWithItems;
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando ventas: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener ventas por rango de fechas (SOLO PAGADAS)
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    return _sales.where((sale) {
      return sale.saleDate.isAfter(start) && 
             sale.saleDate.isBefore(end) &&
             sale.status == 'completada' &&
             sale.paymentMethod != 'credito';
    }).toList();
  }
}