import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'network/dio_factory.dart';

class UserApiService {
  UserApiService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  final Dio _dio;

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _dio.get('/api/users/profile');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[UserApiService] getUserProfile failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    try {
      final response = await _dio.get('/api/user/profile/$userId');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[UserApiService] getUserProfileById failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateUserProfile({
    String? displayName,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) {
        body['displayName'] = displayName;
      }
      if (email != null) {
        body['email'] = email;
      }
      final response = await _dio.put('/api/users/profile', data: body);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[UserApiService] updateUserProfile failed: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/api/users/search',
        queryParameters: {'query': query},
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((item) {
              return Map<String, dynamic>.from(item);
            })
            .toList(growable: false);
      }
    } catch (e) {
      debugPrint('[UserApiService] searchUsers failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> registerMobileUser({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/mobile/register',
        data: <String, dynamic>{
          'username': username,
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[UserApiService] registerMobileUser failed: $e');
    }
    return null;
  }

  Future<int?> getUserCoins() async {
    try {
      final response = await _dio.get('/api/user/coins');
      if (response.data is int) return response.data as int;
      if (response.data is Map && response.data['coins'] != null) {
        return (response.data['coins'] as num).toInt();
      }
    } catch (e) {
      debugPrint('[UserApiService] getUserCoins failed: $e');
    }
    return null;
  }
}
