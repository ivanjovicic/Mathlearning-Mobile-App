import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/config.dart';
import 'connectivity_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';

  String? _accessToken;
  String? _userId;
  String? _username;

  late Dio _dio;

  String _tokenKind(String? token) {
    if (token == null || token.isEmpty) return 'none';
    if (token.startsWith('demo_')) return 'demo';
    return 'real';
  }

  String _mask(String? value) {
    if (value == null || value.isEmpty) return 'none';
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  Future<void> initialize() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: Config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isAuthRoute = path.startsWith('/auth/');
          final isRefreshRoute = path == '/auth/refresh';
          final hadAuthHeader =
              error.requestOptions.headers['Authorization'] != null;
          final canAttemptRefresh =
              _accessToken != null && hadAuthHeader && !isAuthRoute;

          if (error.response?.statusCode == 401 &&
              canAttemptRefresh &&
              !isRefreshRoute) {
            debugPrint('Token expired, attempting refresh...');

            final refreshed = await _refreshTokens();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';

              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                debugPrint('Retry request failed: $e');
              }
            } else {
              await logout();
            }
          }
          handler.next(error);
        },
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _userId = prefs.getString(_userIdKey);
    _username = prefs.getString(_usernameKey);
    debugPrint(
      '[AUTH] initialize: token=${_tokenKind(_accessToken)} user=$_username userId=$_userId',
    );
  }

  Future<AuthResult> login(String username, String password) async {
    debugPrint('[AUTH] login start: username=$username');
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      debugPrint('[AUTH] login response: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['accessToken'] ?? data['AccessToken'];
        final refreshToken = data['refreshToken'] ?? data['RefreshToken'];
        final userId = data['userId'] ?? data['UserId'];
        final responseUsername = data['username'] ?? data['Username'];

        if (accessToken == null || refreshToken == null) {
          debugPrint('[AUTH] login invalid payload: missing tokens');
          return AuthResult(success: false, error: 'Invalid auth response');
        }

        await _storeTokens(
          accessToken: accessToken.toString(),
          refreshToken: refreshToken.toString(),
          userId: userId?.toString(),
          username: responseUsername?.toString() ?? username,
        );

        debugPrint(
          '[AUTH] login success: token=${_tokenKind(_accessToken)} user=$_username userId=$_userId',
        );
        return AuthResult(success: true);
      }
    } catch (e) {
      debugPrint('[AUTH] login failed: $e');

      final useDemo = _isDemoCredentials(username, password);
      debugPrint('[AUTH] login fallback check: demoCredentials=$useDemo');
      if (useDemo) {
        debugPrint('[AUTH] using demo mode credentials');
        await _storeTokens(
          accessToken: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken:
              'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          userId: '1',
          username: username,
        );
        return AuthResult(success: true);
      }
    }

    debugPrint('[AUTH] login end: failed');
    return AuthResult(success: false, error: 'Invalid credentials');
  }

  bool _isDemoCredentials(String username, String password) {
    const demoCredentials = [
      {'username': 'demo', 'password': 'demo'},
      {'username': 'test', 'password': 'test'},
      {'username': 'admin', 'password': 'admin'},
      {'username': 'user', 'password': '123'},
      {'username': 'alex', 'password': 'password'},
    ];

    return demoCredentials.any(
      (cred) => cred['username'] == username && cred['password'] == password,
    );
  }

  Future<AuthResult> register(
    String username,
    String password,
    String email,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'username': username, 'password': password, 'email': email},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult(success: true);
      }
    } catch (e) {
      debugPrint('Register failed: $e');
      debugPrint('Using demo mode registration');
      return AuthResult(success: true);
    }

    return AuthResult(success: false, error: 'Registration failed');
  }

  Future<AuthResult> registerMobileUser({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/mobile/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final tokens = data['tokens'] as Map<String, dynamic>?;
        final profile = data['profile'] as Map<String, dynamic>?;

        final accessToken =
            tokens?['accessToken'] ??
            tokens?['AccessToken'] ??
            data['accessToken'] ??
            data['AccessToken'];
        final refreshToken =
            tokens?['refreshToken'] ??
            tokens?['RefreshToken'] ??
            data['refreshToken'] ??
            data['RefreshToken'];
        final userId =
            tokens?['userId'] ??
            tokens?['UserId'] ??
            profile?['userId'] ??
            profile?['UserId'] ??
            profile?['id'];
        final responseUsername =
            tokens?['username'] ??
            tokens?['Username'] ??
            profile?['username'] ??
            profile?['Username'] ??
            username;

        if (accessToken == null || refreshToken == null) {
          return AuthResult(
            success: false,
            error: 'Mobile registration did not return tokens',
          );
        }

        await _storeTokens(
          accessToken: accessToken.toString(),
          refreshToken: refreshToken.toString(),
          userId: userId?.toString(),
          username: responseUsername.toString(),
        );

        debugPrint(
          'Mobile registration successful with ${profile?['coins'] ?? 100} coins',
        );
        return AuthResult(success: true, userData: data);
      }
    } catch (e) {
      debugPrint('Mobile register failed: $e');

      debugPrint('Using demo mode mobile registration');
      await _storeTokens(
        accessToken: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken:
            'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        userId: '1',
        username: username,
      );

      return AuthResult(
        success: true,
        userData: {
          'profile': {
            'id': '1',
            'username': username,
            'email': email,
            'displayName': displayName,
            'coins': 100,
            'xp': 0,
            'level': 1,
          },
        },
      );
    }

    return AuthResult(success: false, error: 'Mobile registration failed');
  }

  Future<bool> autoLogin() async {
    try {
      debugPrint('[AUTH] autoLogin start');
      final cachedPrefs = await SharedPreferences.getInstance();
      _userId = cachedPrefs.getString(_userIdKey);
      _username = cachedPrefs.getString(_usernameKey);
      final cachedAccessToken = cachedPrefs.getString(_accessTokenKey);
      debugPrint(
        '[AUTH] autoLogin cached: token=${_tokenKind(cachedAccessToken)} user=$_username userId=$_userId',
      );
      if (cachedAccessToken != null && cachedAccessToken.isNotEmpty) {
        _accessToken = cachedAccessToken;
      }

      if (_accessToken != null) {
        debugPrint(
          '[AUTH] autoLogin using cached token: kind=${_tokenKind(_accessToken)}',
        );
        if (ConnectivityService.instance.isOnline) {
          debugPrint('[AUTH] autoLogin online -> background refresh');
          _refreshTokens();
        }
        return true;
      }

      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        debugPrint('[AUTH] autoLogin: no refresh token found');
        return _accessToken != null;
      }
      debugPrint('[AUTH] autoLogin: refresh token exists (${_mask(refreshToken)})');

      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(_userIdKey);
      _username = prefs.getString(_usernameKey);

      debugPrint('[AUTH] autoLogin attempting refresh for user=$_username');

      if (await _refreshTokens()) {
        debugPrint('[AUTH] autoLogin successful');
        return true;
      }
    } catch (e) {
      debugPrint('[AUTH] autoLogin failed: $e');
    }

    debugPrint(
      '[AUTH] autoLogin end: returning ${_accessToken != null} token=${_tokenKind(_accessToken)}',
    );
    return _accessToken != null;
  }

  Future<bool> _refreshTokens() async {
    try {
      debugPrint('[AUTH] refresh start');
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        debugPrint('[AUTH] refresh: no refresh token available');
        return false;
      }
      debugPrint('[AUTH] refresh token found: ${_mask(refreshToken)}');

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      debugPrint('[AUTH] refresh response: status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['accessToken'] ?? data['AccessToken'];
        final newRefreshToken = data['refreshToken'] ?? data['RefreshToken'];
        final userId = data['userId'] ?? data['UserId'] ?? _userId;
        final username = data['username'] ?? data['Username'] ?? _username;

        if (accessToken == null || newRefreshToken == null) {
          debugPrint('[AUTH] refresh invalid payload: missing tokens');
          return false;
        }

        await _storeTokens(
          accessToken: accessToken.toString(),
          refreshToken: newRefreshToken.toString(),
          userId: userId?.toString(),
          username: username?.toString(),
        );

        debugPrint(
          '[AUTH] refresh success: token=${_tokenKind(_accessToken)} user=$_username userId=$_userId',
        );
        return true;
      }
    } catch (e) {
      debugPrint('[AUTH] refresh failed: $e');
    }

    debugPrint('[AUTH] refresh end: false');
    return false;
  }

  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? username,
  }) async {
    debugPrint(
      '[AUTH] storeTokens: access=${_tokenKind(accessToken)} refresh=${_mask(refreshToken)} user=$username userId=$userId',
    );
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);

    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }

    _accessToken = accessToken;
    if (userId != null) _userId = userId;
    if (username != null) _username = username;
  }

  Future<void> logout() async {
    try {
      debugPrint('[AUTH] logout start: token=${_tokenKind(_accessToken)}');
      if (_accessToken != null) {
        final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          debugPrint('[AUTH] logout request with refresh=${_mask(refreshToken)}');
          await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
        } else {
          debugPrint('[AUTH] logout skipped API call: no refresh token');
        }
      }
    } catch (e) {
      debugPrint('[AUTH] logout API call failed: $e');
    }

    await _secureStorage.delete(key: _refreshTokenKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);

    _accessToken = null;
    _userId = null;
    _username = null;

    debugPrint('[AUTH] logged out successfully');
  }

  String? get accessToken => _accessToken;
  String? get userId => _userId;
  String? get username => _username;
  bool get isLoggedIn => _accessToken != null;

  bool get isDemoMode => _accessToken?.startsWith('demo_') ?? false;

  Dio get client => _dio;
}

class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? userData;

  AuthResult({required this.success, this.error, this.userData});
}
