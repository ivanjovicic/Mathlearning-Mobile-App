import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class TokenStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: 'refresh_token', value: token);
    } on MissingPluginException {
      // Widget tests may run without secure storage plugin registration.
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: 'refresh_token');
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    try {
      await _secureStorage.delete(key: 'refresh_token');
    } on MissingPluginException {
      // Nothing to delete in environments without plugin support.
    }
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
