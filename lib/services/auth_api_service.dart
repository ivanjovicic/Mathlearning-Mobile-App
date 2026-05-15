import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'network/dio_factory.dart';

class AuthApiService {
  AuthApiService({Dio? dio}) : _dio = dio ?? DioFactory.create(withAuth: false);

  final Dio _dio;

  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: <String, dynamic>{'Username': username, 'Password': password},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[AuthApiService] login failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> register({
    required String username,
    required String password,
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: <String, dynamic>{
          'username': username,
          'password': password,
          'email': email,
        },
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[AuthApiService] register failed: $e');
    }
    return null;
  }
}
