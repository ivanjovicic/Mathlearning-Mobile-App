import 'package:flutter/foundation.dart';
import '../models/user_settings.dart';
import 'auth_service.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  /// Get user settings from backend
  Future<UserSettings?> getUserSettings(String userId) async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.get('/users/$userId/settings');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data is Map<String, dynamic>) {
          return UserSettings.fromJson(response.data);
        }
      }

      debugPrint('Failed to load user settings: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching user settings: $e');
      return null;
    }
  }

  /// Update user settings on backend
  Future<bool> updateUserSettings(String userId, UserSettings settings) async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.patch(
        '/users/$userId/settings',
        data: settings.toJson(),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('✅ Settings updated for user $userId');
        return true;
      }

      debugPrint('⚠️ Settings update failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error updating settings: $e');
      return false;
    }
  }
}
