import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chase_race.dart';
import '../models/cosmetic_item.dart';
import '../services/auth_service.dart';
import '../services/cosmetics_service.dart';

/// Fetches and caches chase-race data from the backend.
///
/// **No fake data is ever injected.** If the backend is unavailable and there
/// is no prior cached response, [loadRace] returns `null` — callers must treat
/// a null result as "no race available" rather than fabricating participants.
class ChaseRaceService {
  ChaseRaceService._();

  static final ChaseRaceService instance = ChaseRaceService._();

  @visibleForTesting
  ChaseRaceService.test();

  static const String _cachePrefix = 'chase_race.v1.';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Loads the race for [itemId].
  ///
  /// 1. Tries `GET /api/chase-race/{itemId}` (6 s timeout).
  ///    TODO: Backend endpoint `/api/chase-race/*` is not yet confirmed to be available.
  ///    If unavailable, this will fall back to cache and return null if no cache exists.
  /// 2. On success, caches the raw JSON locally.
  /// 3. On failure, falls back to the last cached response.
  /// 4. If neither succeeds, returns `null`.
  Future<ChaseRace?> loadRace({
    required String itemId,
    required String userId,
  }) async {
    final rarity = _rarityFor(itemId);

    // 1. Backend.
    try {
      final client = AuthService.instance.client;
      final response = await client
          .get('/api/chase-race/$itemId')
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 && response.data is Map) {
        final json = Map<String, dynamic>.from(response.data as Map);
        await _writeCache(itemId, json);
        return ChaseRace.fromJson(json, itemRarity: rarity);
      }
    } catch (e) {
      debugPrint('[ChaseRaceService] backend unavailable for $itemId: $e');
    }

    // 2. Local cache.
    return _readCache(itemId, rarity: rarity);
  }

  /// Clears the cache for [itemId]. Call when the user changes their target.
  Future<void> clearCache(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$itemId');
    } catch (e) {
      debugPrint('[ChaseRaceService] clearCache failed: $e');
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  CosmeticRarity _rarityFor(String itemId) {
    final catalog = CosmeticsService.instance.getCatalog();
    return catalog
            .where((e) => e.id == itemId)
            .firstOrNull
            ?.rarity ??
        CosmeticRarity.common;
  }

  Future<void> _writeCache(
    String itemId,
    Map<String, dynamic> json,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$itemId', jsonEncode(json));
    } catch (e) {
      debugPrint('[ChaseRaceService] cache write failed: $e');
    }
  }

  Future<ChaseRace?> _readCache(
    String itemId, {
    required CosmeticRarity rarity,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$itemId');
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ChaseRace.fromJson(json, itemRarity: rarity);
    } catch (e) {
      debugPrint('[ChaseRaceService] cache read failed: $e');
      return null;
    }
  }
}
