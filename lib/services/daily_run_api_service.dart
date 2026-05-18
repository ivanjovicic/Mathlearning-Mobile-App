import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'network/dio_factory.dart';

class DailyRunApiService {
  DailyRunApiService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  final Dio _dio;

  Future<DailyRunChestClaimResponse?> claimChest({
    required String transactionId,
    required DateTime date,
  }) async {
    try {
      final response = await _dio.post(
        '/api/daily-run/chest/claim',
        data: <String, dynamic>{
          'transactionId': transactionId,
          'date':
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        },
      );
      if (response.data is Map<String, dynamic>) {
        return DailyRunChestClaimResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[DailyRunApiService] claimChest failed: $e');
    }
    return null;
  }
}

class DailyRunChestClaimResponse {
  DailyRunChestClaimResponse({
    required this.success,
    required this.date,
    required this.transactionId,
    required this.alreadyClaimed,
    required this.reward,
    required this.balances,
    this.message,
    this.error,
  });

  final bool success;
  final String date;
  final String transactionId;
  final bool alreadyClaimed;
  final DailyRunChestClaimReward reward;
  final DailyRunChestClaimBalances balances;
  final String? message;
  final String? error;

  factory DailyRunChestClaimResponse.fromJson(Map<String, dynamic> json) {
    return DailyRunChestClaimResponse(
      success: json['success'] == true,
      date: json['date']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      alreadyClaimed: json['alreadyClaimed'] == true,
      message: json['message']?.toString(),
      error: json['error']?.toString(),
      reward: DailyRunChestClaimReward.fromJson(
        Map<String, dynamic>.from(json['reward'] as Map? ?? const {}),
      ),
      balances: DailyRunChestClaimBalances.fromJson(
        Map<String, dynamic>.from(json['balances'] as Map? ?? const {}),
      ),
    );
  }
}

class DailyRunChestClaimReward {
  DailyRunChestClaimReward({
    required this.xp,
    required this.coins,
    required this.cosmeticFragment,
    required this.fragmentCopies,
  });

  final int xp;
  final int coins;
  final String cosmeticFragment;
  final int fragmentCopies;

  factory DailyRunChestClaimReward.fromJson(Map<String, dynamic> json) {
    return DailyRunChestClaimReward(
      xp: _asInt(json['xp']) ?? 0,
      coins: _asInt(json['coins']) ?? 0,
      cosmeticFragment: json['cosmeticFragment']?.toString() ?? '',
      fragmentCopies: _asInt(json['fragmentCopies']) ?? 1,
    );
  }
}

class DailyRunChestClaimBalances {
  DailyRunChestClaimBalances({
    required this.xp,
    required this.level,
    required this.coins,
  });

  final int xp;
  final int level;
  final int coins;

  factory DailyRunChestClaimBalances.fromJson(Map<String, dynamic> json) {
    return DailyRunChestClaimBalances(
      xp: _asInt(json['xp']) ?? 0,
      level: _asInt(json['level']) ?? 1,
      coins: _asInt(json['coins']) ?? 0,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
