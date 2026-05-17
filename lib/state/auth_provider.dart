import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/offline_manager.dart';

const String networkErrorKey = '__network_error__';
const String authLoginFailedKey = '__auth_login_failed__';
const String authInvalidCredentialsKey = '__auth_invalid_credentials__';
const String authUsernameTakenKey = '__auth_username_taken__';
const String authEmailTakenKey = '__auth_email_taken__';

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
  bool get isDemoMode => _authService.isDemoMode;

  // Auto-login on app start
  Future<bool> autoLogin() async {
    _setLoading(true);

    try {
      debugPrint('[AUTH_PROVIDER] autoLogin start');
      final success = await _authService.autoLogin().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      debugPrint(
        '[AUTH_PROVIDER] autoLogin result: success=$success demo=$isDemoMode user=$username',
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
      debugPrint('[AUTH_PROVIDER] login start: username=$username');
      final result = await _authService.login(username, password);

      if (result.success) {
        debugPrint(
          '[AUTH_PROVIDER] login success: demo=$isDemoMode tokenPresent=${token != null} user=$username',
        );
        await OfflineManager.instance.syncPendingData();
        notifyListeners();
        return true;
      } else {
        debugPrint('[AUTH_PROVIDER] login failed: error=${result.error}');
        _setError(
          _localizeAuthError(result.error, fallbackKey: authLoginFailedKey),
        );
        return false;
      }
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] login exception: $e');
      _setError(networkErrorKey);
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
            fallbackKey: authLoginFailedKey,
          ),
        );
        return false;
      }
    } catch (e) {
      _setError(networkErrorKey);
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

  String _localizeAuthError(String? rawError, {required String fallbackKey}) {
    final raw = (rawError ?? '').trim();
    if (raw.isEmpty) return fallbackKey;

    final value = raw.toLowerCase();
    if (value.contains('invalid credentials') ||
        value.contains('wrong password') ||
        value.contains('unauthorized')) {
      return authInvalidCredentialsKey;
    }
    if (value.contains('username') &&
        (value.contains('exists') || value.contains('taken'))) {
      return authUsernameTakenKey;
    }
    if (value.contains('email') &&
        (value.contains('exists') || value.contains('taken'))) {
      return authEmailTakenKey;
    }
    if (value.contains('network') ||
        value.contains('timeout') ||
        value.contains('connection') ||
        value.contains('socket')) {
      return networkErrorKey;
    }
    return fallbackKey;
  }
}
