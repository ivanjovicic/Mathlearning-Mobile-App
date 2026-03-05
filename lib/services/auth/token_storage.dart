import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: 'refresh_token', value: token);
  }

  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: 'refresh_token');
  }

  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<void> saveAccessToken(String token) async {
    // Access token is stored in memory only for security reasons.
    _accessToken = token;
  }

  static String? _accessToken;

  Future<String?> getAccessToken() async {
    return _accessToken;
  }

  Future<void> clear() async {
    _accessToken = null;
    await deleteRefreshToken();
  }
}
