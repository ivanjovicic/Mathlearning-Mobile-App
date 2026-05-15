import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'network/dio_factory.dart';

class CosmeticsApiService {
  CosmeticsApiService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  final Dio _dio;

  Future<Map<String, dynamic>?> fetchInventory() async {
    try {
      final response = await _dio.get('/api/cosmetics/inventory');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[CosmeticsApiService] fetchInventory failed: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchAvatar() async {
    try {
      final response = await _dio.get('/api/cosmetics/avatar');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[CosmeticsApiService] fetchAvatar failed: $e');
    }
    return null;
  }
}
