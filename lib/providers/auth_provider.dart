import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final email = await _authService.getUserEmail();
        if (email != null) {
          _currentUser = await _databaseService.getUserByEmail(email);
        }
      }
    } catch (e) {
      _errorMessage = 'Error al recuperar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _databaseService.login(email, password);
      if (user != null) {
        _currentUser = user;
        await _authService.saveUser(user);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email o contraseña incorrectos';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error al iniciar sesión: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName, String role) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final newUser = User(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
        isActive: true,
      );

      final success = await _databaseService.createUser(newUser);
      if (success) {
        _currentUser = newUser;
        await _authService.saveUser(newUser);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Error al registrar usuario';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = '';
    _isLoading = false;
    await _authService.logout();
    notifyListeners();
  }

  Future<void> clearSession() async {
    _currentUser = null;
    _errorMessage = '';
    _isLoading = false;
    await _authService.logout();
    notifyListeners();
  }
}