import 'package:flutter/material.dart';
import '../models/client.dart';
import '../services/database_service.dart';

class ClientProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();

  List<Client> _clients = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadClients(String businessRuc) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _clients = await _databaseService.getAllClients(businessRuc);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando clientes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addClient(Client client) async {
    try {
      await _databaseService.createClient(client);
      await loadClients(client.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error creando cliente: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClient(Client client) async {
    try {
      await _databaseService.updateClient(client);
      await loadClients(client.businessRuc!);
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando cliente: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClient(int id, String businessRuc) async {
    try {
      await _databaseService.deleteClient(id, businessRuc);
      await loadClients(businessRuc);
      return true;
    } catch (e) {
      _errorMessage = 'Error eliminando cliente: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Client?> getClientById(int id, String businessRuc) async {
    return await _databaseService.getClientById(id, businessRuc);
  }

  Future<List<Client>> getClientsWithDebt(String businessRuc) async {
    return await _databaseService.getClientsWithDebt(businessRuc);
  }

  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;
    return _clients
        .where((client) =>
            client.name.toLowerCase().contains(query.toLowerCase()) ||
            client.email.toLowerCase().contains(query.toLowerCase()) ||
            client.phone.contains(query))
        .toList();
  }

  double get totalDebt {
    return _clients.fold(0, (sum, client) => sum + (client.debt));
  }

  Future<bool> redeemPoints(Client client, int pointsToRedeem) async {
    if (client.loyaltyPoints < pointsToRedeem) return false;
    
    final updatedClient = client.copyWith(
      loyaltyPoints: client.loyaltyPoints - pointsToRedeem,
    );
    
    return await updateClient(updatedClient);
  }
}
