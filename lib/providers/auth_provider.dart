import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  User? _currentUser;
  List<User> _allUsers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  User? get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;
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

  Future<bool> register({
    required String email, 
    required String password, 
    required String fullName, 
    required String role,
    required String businessRuc,
    required String businessName,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final newUser = User(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        businessRuc: businessRuc,
        businessName: businessName,
        createdAt: DateTime.now(),
        // Si el rol es admin, activar por defecto. Si es empleado, esperar aprobación.
        isActive: role == 'admin',
      );

      final success = await _databaseService.createUser(newUser);
      if (success) {
        // ← NUEVO: Si es admin, crear también la entrada de la empresa
        if (role == 'admin') {
          await _databaseService.createBusiness(businessRuc, businessName);
          _currentUser = newUser;
          await _authService.saveUser(newUser);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Registro exitoso. Tu cuenta debe ser aprobada por el administrador antes de entrar.';
          _isLoading = false;
          notifyListeners();
          return true; // Retornamos true porque el registro fue exitoso
        }
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

  Future<bool> createUserByAdmin(String email, String password, String fullName, String role) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final newUser = User(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        businessRuc: _currentUser!.businessRuc,
        businessName: _currentUser!.businessName,
        createdAt: DateTime.now(),
        isActive: true,
      );
      final success = await _databaseService.createUser(newUser);
      if (success) {
        await loadAllUsers();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error creando usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
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

  // ==================== GESTIÓN DE USUARIOS (ADMIN) ====================
  Future<void> loadAllUsers() async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      _allUsers = await _databaseService.getAllUsersByBusiness(_currentUser!.businessRuc);
    } catch (e) {
      _errorMessage = 'Error cargando usuarios: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserInfo(User user) async {
    try {
      final success = await _databaseService.updateUser(user);
      if (success) {
        await loadAllUsers();
        // Si el usuario actualizado es el actual, actualizarlo también
        if (_currentUser?.id == user.id) {
          _currentUser = user;
        }
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error actualizando usuario: $e';
    }
    return false;
  }
}
