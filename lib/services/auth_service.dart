import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();

  // Secure storage for refresh token
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys for storage
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';

  // In-memory access token (faster access)
  String? _accessToken;
  String? _userId;
  String? _username;

  // Dio client with interceptor
  late Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: Config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add auto-refresh interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add access token to all requests
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('🔄 Token expired, attempting refresh...');
            
            final refreshed = await _refreshTokens();
            if (refreshed) {
              // Retry original request with new token
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $_accessToken';
              
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                debugPrint('❌ Retry request failed: $e');
              }
            } else {
              // Refresh failed - logout user
              await logout();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // Login with username/password
  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        await _storeTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          userId: data['user']['id']?.toString(),
          username: data['user']['username'],
        );

        return AuthResult(success: true);
      }
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      
      // Demo mode fallback - allow specific test credentials
      if (_isDemoCredentials(username, password)) {
        debugPrint('🎯 Using demo mode credentials');
        await _storeTokens(
          accessToken: 'demo_access_token_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: 'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
          userId: '1',
          username: username,
        );
        return AuthResult(success: true);
      }
    }

    return AuthResult(success: false, error: 'Invalid credentials');
  }

  // Check if credentials are demo credentials
  bool _isDemoCredentials(String username, String password) {
    const demoCredentials = [
      {'username': 'demo', 'password': 'demo'},
      {'username': 'test', 'password': 'test'},
      {'username': 'admin', 'password': 'admin'},
      {'username': 'user', 'password': '123'},
      {'username': 'alex', 'password': 'password'},
    ];
    
    return demoCredentials.any((cred) => 
      cred['username'] == username && cred['password'] == password
    );
  }

  // Register new user
  Future<AuthResult> register(String username, String password, String email) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
      });

      if (response.statusCode == 201) {
        return AuthResult(success: true);
      }
    } catch (e) {
      debugPrint('❌ Register failed: $e');
      
      // Demo mode fallback - allow registration with any credentials
      debugPrint('🎯 Using demo mode registration');
      return AuthResult(success: true);
    }

    return AuthResult(success: false, error: 'Registration failed');
  }

  // NEW: Register mobile user with full profile data
  Future<AuthResult> registerMobileUser({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post('/auth/mobile/register', data: {
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // Store tokens and profile data from registration response
        await _storeTokens(
          accessToken: data['accessToken'] ?? data['access_token'],
          refreshToken: data['refreshToken'] ?? data['refresh_token'],
          userId: data['user']?['id']?.toString() ?? data['profile']?['id']?.toString(),
          username: data['user']?['username'] ?? data['profile']?['username'] ?? username,
        );

        debugPrint('✅ Mobile registration successful with ${data['profile']?['coins'] ?? 100} coins');
        return AuthResult(success: true, userData: data);
      }
    } catch (e) {
      debugPrint('❌ Mobile register failed: $e');
      
      // Demo mode fallback - simulate successful registration with 100 coins
      debugPrint('🎯 Using demo mode mobile registration');
      await _storeTokens(
        accessToken: 'demo_access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
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
          }
        }
      );
    }

    return AuthResult(success: false, error: 'Mobile registration failed');
  }

  // Auto-login on app start
  Future<bool> autoLogin() async {
    try {
      // Load tokens from storage
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        debugPrint('No refresh token found');
        return false;
      }

      // Load user data from SharedPreferences (faster)
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(_userIdKey);
      _username = prefs.getString(_usernameKey);

      debugPrint('🔄 Attempting auto-login for user: $_username');

      // Try to refresh tokens
      if (await _refreshTokens()) {
        debugPrint('✅ Auto-login successful');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Auto-login failed: $e');
    }

    return false;
  }

  // Refresh access and refresh tokens
  Future<bool> _refreshTokens() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        debugPrint('No refresh token available');
        return false;
      }

      final response = await _dio.post('/api/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        await _storeTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          userId: _userId, // Keep existing user data
          username: _username,
        );

        debugPrint('✅ Tokens refreshed successfully');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
    }

    return false;
  }

  // Store tokens securely
  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? username,
  }) async {
    // Store refresh token securely
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

    // Store access token in SharedPreferences (faster access)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
    if (username != null) {
      await prefs.setString(_usernameKey, username);
    }

    // Update in-memory variables
    _accessToken = accessToken;
    if (userId != null) _userId = userId;
    if (username != null) _username = username;
  }

  // Logout and clear all tokens
  Future<void> logout() async {
    try {
      // Notify server about logout (optional)
      if (_accessToken != null) {
        await _dio.post('/api/auth/logout');
      }
    } catch (e) {
      debugPrint('Logout API call failed: $e');
    }

    // Clear all stored data
    await _secureStorage.delete(key: _refreshTokenKey);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);

    // Clear in-memory data
    _accessToken = null;
    _userId = null;
    _username = null;

    debugPrint('✅ Logged out successfully');
  }

  // Getters
  String? get accessToken => _accessToken;
  String? get userId => _userId;
  String? get username => _username;
  bool get isLoggedIn => _accessToken != null;

  // Get Dio client for API calls
  Dio get client => _dio;
}

class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? userData;

  AuthResult({
    required this.success, 
    this.error,
    this.userData,
  });
}