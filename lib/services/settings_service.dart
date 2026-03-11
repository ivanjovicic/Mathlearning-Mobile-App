import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/user_settings.dart';
import 'auth_service.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  bool _isUnavailableStatus(int? statusCode) => statusCode == 404;

  /// Get user settings from backend.
  Future<UserSettings?> getUserSettings(String userId) async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.get(
        '/users/$userId/settings',
        options: Options(
          validateStatus: (status) =>
              status != null && (status < 400 || _isUnavailableStatus(status)),
        ),
      );

      if (_isUnavailableStatus(response.statusCode)) {
        return null;
      }

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data is Map<String, dynamic>) {
        return UserSettings.fromJson(response.data);
      }

      debugPrint('Failed to load user settings: ${response.statusCode}');
      return null;
    } catch (e) {
      if (e is DioException && _isUnavailableStatus(e.response?.statusCode)) {
        return null;
      }
      debugPrint('Error fetching user settings: $e');
      return null;
    }
  }

  /// Update user settings on backend.
  Future<bool> updateUserSettings(String userId, UserSettings settings) async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.patch(
        '/users/$userId/settings',
        data: settings.toJson(),
        options: Options(
          validateStatus: (status) =>
              status != null && (status < 400 || _isUnavailableStatus(status)),
        ),
      );

      if (_isUnavailableStatus(response.statusCode)) {
        return false;
      }

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('Settings updated for user $userId');
        return true;
      }

      debugPrint('Settings update failed: ${response.statusCode}');
      return false;
    } catch (e) {
      if (e is DioException && _isUnavailableStatus(e.response?.statusCode)) {
        return false;
      }
      debugPrint('Error updating settings: $e');
      return false;
    }
  }
}
