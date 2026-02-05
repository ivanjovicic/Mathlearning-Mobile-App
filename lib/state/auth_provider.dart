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
      final success = await _authService.autoLogin().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (success) {
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Silent fallback to login screen (without noisy startup error).
      debugPrint('Auto-login fallback: $e');
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
        _setError(
          _localizeAuthError(result.error, fallback: 'Prijava nije uspela'),
        );
        return false;
      }
    } catch (e) {
      _setError('Doslo je do greske u mrezi');
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
        _setError(
          _localizeAuthError(
            result.error,
            fallback: 'Registracija nije uspela',
          ),
        );
        return false;
      }
    } catch (e) {
      _setError('Doslo je do greske u mrezi');
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

  String _localizeAuthError(String? rawError, {required String fallback}) {
    final raw = (rawError ?? '').trim();
    if (raw.isEmpty) return fallback;

    final value = raw.toLowerCase();
    if (value.contains('invalid credentials') ||
        value.contains('wrong password') ||
        value.contains('unauthorized')) {
      return 'Pogresni podaci za prijavu.';
    }
    if (value.contains('username') &&
        (value.contains('exists') || value.contains('taken'))) {
      return 'Korisnicko ime je zauzeto.';
    }
    if (value.contains('email') &&
        (value.contains('exists') || value.contains('taken'))) {
      return 'Imejl adresa je vec zauzeta.';
    }
    if (value.contains('network') ||
        value.contains('timeout') ||
        value.contains('connection') ||
        value.contains('socket')) {
      return 'Doslo je do greske u mrezi.';
    }
    return fallback;
  }
}
