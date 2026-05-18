import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';

import '../models/api_result.dart' as models_api;
import 'auth/auth_controller.dart';
import 'auth/auth_client.dart';
import 'auth/auth_repository.dart';
import 'auth/token_storage.dart';
import 'network/dio_factory.dart';
import '../services/user_api_service.dart';

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
  late final AuthController controller;
  String? _accessToken;
  String? _userId;
  String? _username;
  bool _isDemoMode = false;
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  AuthService._() {
    _dio = DioFactory.create(withAuth: false);
    _tokenStorage = TokenStorage();
    _repo = AuthRepository(_dio, _tokenStorage);
    controller = AuthController(_repo);
    AuthClient(
      _dio,
      _tokenStorage,
      _repo,
      onSessionExpired: _handleSessionExpiredFromClient,
    );
  }

  Future<void> initialize() async {
    await _tokenStorage.getRefreshToken();
    await _refreshIdentityCache();
  }

  Dio get client => _dio;
  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  Future<AuthResultShim> login(String username, String password) async {
    final res = await controller.login(username, password);
    if (res is models_api.ApiSuccess<bool>) {
      await _refreshIdentityCache();
      return AuthResultShim(true);
    }
    if (res is models_api.ApiFailure) {
      final err = (res as models_api.ApiFailure).error;
      return AuthResultShim(false, err.message);
    }
    return AuthResultShim(false, 'Unknown error');
  }

  Future<AuthResultShim> register(
    String username,
    String password,
    String email,
  ) async {
    final res = await _repo.register(username, password, email);
    if (res is models_api.ApiSuccess<Map<String, dynamic>>) {
      return AuthResultShim(true);
    }
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
      final res = await UserApiService().registerMobileUser(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );
      if (res != null) {
        return AuthResultShim(true);
      }
      return AuthResultShim(false, 'Registration failed');
    } catch (e) {
      return AuthResultShim(false, e.toString());
    }
  }

  Future<bool> autoLogin() async {
    await controller.autoLogin();
    if (controller.state == AuthState.authenticated) {
      await _refreshIdentityCache();
    }
    return controller.state == AuthState.authenticated;
  }

  Future<void> logout() async {
    await controller.logout();
    _accessToken = null;
    _userId = null;
    _username = null;
    _isDemoMode = false;
  }

  Future<void> _handleSessionExpiredFromClient() async {
    await logout();
    _sessionExpiredController.add(null);
  }

  String? get userId => _userId;
  String? get username => _username;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => controller.state == AuthState.authenticated;
  bool get isDemoMode => _isDemoMode;

  Future<void> _refreshIdentityCache() async {
    final token = await _tokenStorage.getAccessToken();
    _accessToken = token;
    if (token == null || token.isEmpty) {
      _userId = null;
      _username = null;
      _isDemoMode = false;
      return;
    }

    final payload = _decodeJwtPayload(token);
    _userId = _readClaimFromPayload(payload, const [
      'sub',
      'nameid',
      'userId',
      'uid',
    ]);
    _username = _readClaimFromPayload(payload, const [
      'unique_name',
      'preferred_username',
      'username',
      'name',
    ]);
    _isDemoMode = _readDemoModeFromPayload(payload);
  }

  String? _readClaimFromPayload(
    Map<String, dynamic>? payload,
    List<String> keys,
  ) {
    if (payload == null) {
      return null;
    }
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  bool _readDemoModeFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) {
      return false;
    }

    bool asBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' ||
            normalized == '1' ||
            normalized == 'demo';
      }
      return false;
    }

    if (asBool(payload['is_demo']) || asBool(payload['isDemo'])) {
      return true;
    }

    final accountType = (payload['account_type'] ?? payload['accountType'])
        ?.toString();
    if (accountType != null && accountType.toLowerCase() == 'demo') {
      return true;
    }

    final mode = payload['mode']?.toString();
    if (mode != null && mode.toLowerCase() == 'demo') {
      return true;
    }

    return false;
  }

  Map<String, dynamic>? _decodeJwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) {
      return null;
    }
    try {
      final normalized = base64Url.normalize(parts[1]);
      final bytes = base64Url.decode(normalized);
      final json = utf8.decode(bytes);
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
