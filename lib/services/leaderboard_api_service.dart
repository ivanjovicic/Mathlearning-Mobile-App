import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/leaderboard_models.dart';
import '../models/school_leaderboard_models.dart';
import 'network/dio_factory.dart';

class LeaderboardApiService {
  LeaderboardApiService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  final Dio _dio;

  Future<LeaderboardResponse?> fetchLeaderboard({
    required String scope,
    required String period,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{
        'scope': scope,
        'period': period,
        'limit': limit,
      };
      if (cursor != null && cursor.isNotEmpty) {
        query['cursor'] = cursor;
      }
      final response = await _dio.get(
        '/api/leaderboard',
        queryParameters: query,
      );
      if (response.data is Map<String, dynamic>) {
        return LeaderboardResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[LeaderboardApiService] fetchLeaderboard failed: $e');
    }
    return null;
  }

  Future<List<RivalLeaderboardEntry>?> fetchRivals({
    required String period,
  }) async {
    try {
      final response = await _dio.get(
        '/api/leaderboard/rivals',
        queryParameters: <String, dynamic>{'period': period},
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map(
              (item) => RivalLeaderboardEntry.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      if (response.data is Map<String, dynamic>) {
        final payload = response.data as Map<String, dynamic>;
        final rawItems = (payload['items'] ?? payload['entries']) as List?;
        if (rawItems == null) {
          return const <RivalLeaderboardEntry>[];
        }
        return rawItems
            .whereType<Map>()
            .map(
              (item) => RivalLeaderboardEntry.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[LeaderboardApiService] fetchRivals failed: $e');
    }
    return null;
  }

  Future<List<RivalLeaderboardEntry>?> fetchLeaderboardRivals({
    required String period,
  }) async {
    try {
      final resp = await _dio.get(
        '/api/leaderboard/friends',
        queryParameters: <String, dynamic>{'period': period},
      );
      if (resp.data is List) {
        return (resp.data as List)
            .whereType<Map>()
            .map(
              (item) => RivalLeaderboardEntry.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      if (resp.data is Map<String, dynamic>) {
        final payload = resp.data as Map<String, dynamic>;
        final rawItems = (payload['items'] ?? payload['entries']) as List?;
        if (rawItems == null) {
          return const <RivalLeaderboardEntry>[];
        }
        return rawItems
            .whereType<Map>()
            .map(
              (item) => RivalLeaderboardEntry.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
    } catch (_) {}
    return null;
  }

  Future<SchoolLeaderboardResponse?> fetchSchoolVsSchoolLeaderboard({
    required String period,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{'period': period, 'limit': limit};
      if (cursor != null && cursor.isNotEmpty) {
        query['cursor'] = cursor;
      }
      final response = await _dio.get(
        '/api/leaderboard/schools',
        queryParameters: query,
      );
      if (response.data is Map<String, dynamic>) {
        return SchoolLeaderboardResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<SchoolLeaderboardFeed?> fetchSchoolLeaderboard({
    required String period,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{'period': period, 'limit': limit};
      if (cursor != null && cursor.isNotEmpty) {
        query['cursor'] = cursor;
      }
      final response = await _dio.get(
        '/api/leaderboard/schools',
        queryParameters: query,
      );
      if (response.data is Map<String, dynamic>) {
        return SchoolLeaderboardFeed.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[LeaderboardApiService] fetchSchoolLeaderboard failed: $e');
    }
    return null;
  }

  Future<SchoolLeaderboardDetail?> fetchSchoolLeaderboardDetail({
    required int schoolId,
    required String period,
  }) async {
    try {
      final response = await _dio.get(
        '/api/leaderboard/schools/$schoolId',
        queryParameters: {'period': period},
      );
      if (response.data is Map<String, dynamic>) {
        return SchoolLeaderboardDetail.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint(
        '[LeaderboardApiService] fetchSchoolLeaderboardDetail failed: $e',
      );
    }
    return null;
  }

  Future<List<SchoolLeaderboardHistoryPoint>?> fetchSchoolLeaderboardHistory({
    required int schoolId,
    required String period,
    int take = 30,
  }) async {
    try {
      final response = await _dio.get(
        '/api/leaderboard/schools/history/$schoolId',
        queryParameters: <String, dynamic>{'period': period, 'take': take},
      );
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map(
              (item) => SchoolLeaderboardHistoryPoint.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>)['items'] is List) {
        return ((response.data as Map<String, dynamic>)['items'] as List)
            .whereType<Map>()
            .map(
              (item) => SchoolLeaderboardHistoryPoint.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint(
        '[LeaderboardApiService] fetchSchoolLeaderboardHistory failed: $e',
      );
    }
    return null;
  }
}
