import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weekly_featured_cosmetic.dart';

class WeeklyFeaturedService {
  WeeklyFeaturedService._();

  static final WeeklyFeaturedService instance = WeeklyFeaturedService._();

  static const _storagePrefix = 'weekly_featured_cosmetic_state_v1.';

  Future<WeeklyFeaturedState> loadState({String? userId, DateTime? now}) async {
    final currentSet = WeeklyFeaturedRotationCatalog.currentSet(now: now);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(userId));
      if (raw == null || raw.isEmpty) {
        final fresh = WeeklyFeaturedState(
          activeSet: currentSet,
          updatedAt: DateTime.now(),
        );
        await saveState(fresh, userId: userId);
        return fresh;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        final fresh = WeeklyFeaturedState(
          activeSet: currentSet,
          updatedAt: DateTime.now(),
        );
        await saveState(fresh, userId: userId);
        return fresh;
      }

      final saved = WeeklyFeaturedState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (saved.activeSet.rotationId != currentSet.rotationId) {
        final rotated = saved.copyWith(
          activeSet: currentSet,
          updatedAt: DateTime.now(),
        );
        await saveState(rotated, userId: userId);
        return rotated;
      }
      return saved;
    } catch (e) {
      debugPrint('[WeeklyFeaturedService] load state failed: $e');
      return WeeklyFeaturedState(
        activeSet: currentSet,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> saveState(WeeklyFeaturedState state, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey(userId), jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[WeeklyFeaturedService] save state failed: $e');
    }
  }

  String chooseDailyRunFragment({
    required WeeklyFeaturedCosmeticSet set,
    required String baseFragmentName,
    required String userId,
    DateTime? now,
  }) {
    final baseItemId = _itemIdForFragment(baseFragmentName);
    if (baseItemId != null && set.containsItem(baseItemId)) {
      return baseFragmentName;
    }

    final featuredDropIds = set.itemIds
        .where((id) => _fragmentNameForItemId(id) != null)
        .toList(growable: false);
    if (featuredDropIds.isEmpty) return baseFragmentName;

    final day = now ?? DateTime.now();
    final seed =
        '${set.rotationId}|$userId|${day.year}-${day.month}-${day.day}|featured';
    final hash = _hash(seed);

    // Local deterministic weighting: featured-eligible items get picked on
    // most days, but not every day. The UI never shows odds.
    if (hash % 100 >= 65) return baseFragmentName;

    final itemId = featuredDropIds[hash % featuredDropIds.length];
    return _fragmentNameForItemId(itemId) ?? baseFragmentName;
  }

  String _storageKey(String? userId) {
    final safeUserId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    return '$_storagePrefix$safeUserId';
  }

  int _hash(String seed) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return hash;
  }

  String? _itemIdForFragment(String fragmentName) {
    final normalized = fragmentName.toLowerCase();
    if (normalized.contains('neon') || normalized.contains('burst')) {
      return 'effect_neon_number_burst';
    }
    if (normalized.contains('comet') || normalized.contains('frame')) {
      return 'frame_comet';
    }
    if (normalized.contains('nova') || normalized.contains('trail')) {
      return 'effect_nova_trail';
    }
    return null;
  }

  String? _fragmentNameForItemId(String itemId) {
    return switch (itemId) {
      'effect_nova_trail' => 'Nova Trail Fragment',
      'frame_comet' => 'Comet Frame Fragment',
      'effect_neon_number_burst' => 'Neon Number Burst Fragment',
      _ => null,
    };
  }
}
