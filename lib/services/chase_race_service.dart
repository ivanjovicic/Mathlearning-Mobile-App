import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chase_race.dart';

/// Handles chase-race availability for the mobile client.
///
/// Backend support for chase endpoints is currently unavailable, so
/// [loadRace] always returns `null`. Callers should render the feature as
/// unavailable and must not fabricate race participants.
class ChaseRaceService {
  ChaseRaceService._();

  static final ChaseRaceService instance = ChaseRaceService._();

  @visibleForTesting
  ChaseRaceService.test();

  static const String _cachePrefix = 'chase_race.v1.';

  Future<ChaseRace?> loadRace({
    required String itemId,
    required String userId,
  }) async {
    debugPrint(
      '[ChaseRaceService] loadRace unavailable: chase endpoints are not supported',
    );
    return null;
  }

  /// Clears cached race data for [itemId].
  Future<void> clearCache(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$itemId');
    } catch (e) {
      debugPrint('[ChaseRaceService] clearCache failed: $e');
    }
  }
}
