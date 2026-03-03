import 'package:dio/dio.dart';

import '../models/api_result.dart' as models_api;
import 'auth/auth_repository.dart';
import 'auth/auth_client.dart';
import 'auth/token_storage.dart';
import 'auth/auth_controller.dart';
import '../services/api_service.dart';

/// Backwards-compatible `AuthService` wrapper expected by legacy code.
/// Legacy-style result object expected by older callers.
/// Provides `.success` and `.error` members.
class AuthResultShim {
  final bool success;
  final String? error;

  AuthResultShim(this.success, [this.error]);
}

class AuthService {
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  late final TokenStorage _tokenStorage;
  late final Dio _dio;
  late final AuthRepository _repo;
  late final AuthClient _client;
  late final AuthController controller;

  AuthService._() {
    _dio = Dio();
    _tokenStorage = TokenStorage();
    _repo = AuthRepository(_dio, _tokenStorage);
    _client = AuthClient(_dio, _tokenStorage, _repo);
    controller = AuthController(_repo);
  }

  Dio get client => _dio;

  Future<AuthResultShim> login(String username, String password) async {
    final res = await controller.login(username, password);
    if (res is models_api.ApiSuccess<bool>) return AuthResultShim(true);
    if (res is models_api.ApiFailure) {
      final err = (res as models_api.ApiFailure).error;
      return AuthResultShim(false, err.message);
    }
    return AuthResultShim(false, 'Unknown error');
  }

  Future<AuthResultShim> register(String username, String password, String email) async {
    final res = await _repo.register(username, password, email);
    if (res is models_api.ApiSuccess<Map<String, dynamic>>) return AuthResultShim(true);
    if (res is models_api.ApiFailure) {
      final err = (res as models_api.ApiFailure).error;
      return AuthResultShim(false, err.message);
    }
    return AuthResultShim(false, 'Unknown error');
  }

  Future<AuthResultShim> registerMobileUser({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final res = await ApiService().registerMobileUser(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );
      if (res != null) return AuthResultShim(true);
      return AuthResultShim(false, 'Registration failed');
    } catch (e) {
      return AuthResultShim(false, e.toString());
    }
  }

  Future<bool> autoLogin() async {
    await controller.autoLogin();
    return controller.state == AuthState.authenticated;
  }

  Future<void> logout() async {
    await controller.logout();
  }

  String? get userId => null;
  String? get username => null;
  String? get accessToken => null;
  bool get isLoggedIn => controller.state == AuthState.authenticated;
  bool get isDemoMode => false;
}
