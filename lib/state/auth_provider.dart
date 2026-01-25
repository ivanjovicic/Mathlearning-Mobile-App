import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authService.isLoggedIn;
  String? get token => _authService.accessToken;
  String? get userId => _authService.userId;
  String? get username => _authService.username;

  // Auto-login on app start
  Future<bool> autoLogin() async {
    _setLoading(true);
    
    try {
      final success = await _authService.autoLogin();
      if (success) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      _setError('Auto-login failed');
    } finally {
      _setLoading(false);
    }
    
    return false;
  }

  // Login with username/password
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.login(username, password);
      
      if (result.success) {
        notifyListeners();
        return true;
      } else {
        _setError(result.error ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register new user
  Future<bool> register(String username, String password, String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.register(username, password, email);
      
      if (result.success) {
        return true;
      } else {
        _setError(result.error ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
