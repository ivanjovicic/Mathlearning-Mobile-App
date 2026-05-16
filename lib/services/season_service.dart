import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cosmetic_item.dart';
import '../models/season.dart';
import 'auth_service.dart';
import 'cosmetics_service.dart';

/// Loads season data (backend-first, local-catalog fallback) and persists
/// per-user season progress in SharedPreferences.
///
/// Season data is backend-ready: the [loadActiveSeason] method first attempts
/// a real API call. On failure it falls back to the built-in quarter-based
/// local catalog — no fake data is ever returned for other users.
class SeasonService {
  static final SeasonService instance = SeasonService._();
  SeasonService._();

  /// Test-only subclassing constructor. Subclasses can override individual
  /// methods to replace network / storage with in-memory stubs.
  @visibleForTesting
  SeasonService.test();

  /// Computes the Daily Run season XP for the given multiplier without
  /// requiring an instance. Extracted so tests can verify the formula.
  @visibleForTesting
  static int dailyRunSeasonXpFor(double streakMultiplier) {
    return (30 * streakMultiplier).round().clamp(30, 90);
  }

  static const String _progressKeyPrefix = 'season_progress.v1.';
  static const String _cachedSeasonKey = 'season_catalog_cache.v1';

  // ── Load current season ────────────────────────────────────────

  /// Returns the active season for [now].
  /// Tries the backend first, then the local cache, then generates from the
  /// local quarter-based catalog (guaranteed non-null, offline-first).
  Future<Season?> loadActiveSeason({DateTime? now}) async {
    final reference = now ?? DateTime.now();

    // 1. Try backend.
    try {
      final client = AuthService.instance.client;
      final response = await client
          .get('/api/seasons/active')
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200 && response.data is Map) {
        final season = Season.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        await _cacheSeasonLocally(season);
        return season;
      }
    } catch (e) {
      debugPrint('[SeasonService] Backend unavailable, using local: $e');
    }

    // 2. Try locally-cached season (from last successful backend response).
    final cached = await _loadCachedSeason();
    if (cached != null && cached.status(reference) != SeasonStatus.ended) {
      return cached;
    }

    // 3. Fallback: generate from local quarter-based catalog.
    return _quarterSeason(reference);
  }

  // ── Season progress persistence ────────────────────────────────

  Future<SeasonProgress> loadProgress({
    required String seasonId,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey(userId, seasonId));
      if (raw != null) {
        return SeasonProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (e) {
      debugPrint('[SeasonService] loadProgress failed: $e');
    }
    return SeasonProgress.empty(seasonId: seasonId, userId: userId);
  }

  Future<bool> saveProgress(SeasonProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _progressKey(progress.userId, progress.seasonId),
        jsonEncode(progress.toJson()),
      );
      return true;
    } catch (e) {
      debugPrint('[SeasonService] saveProgress failed: $e');
      return false;
    }
  }

  // ── Reward claiming ────────────────────────────────────────────

  /// Grants the reward for [milestone] to the user.
  ///
  /// Cosmetic / fragment / trail rewards are persisted through
  /// [CosmeticsService.unlockItem] so they are real, owned items.
  /// Badge rewards are recorded only in [SeasonProgress.archivedBadgeIds].
  /// Returns true if the grant succeeded.
  Future<bool> grantMilestoneReward({
    required SeasonMilestone milestone,
    required String userId,
  }) async {
    switch (milestone.rewardType) {
      case SeasonRewardType.cosmetic:
      case SeasonRewardType.trail:
      case SeasonRewardType.profileEffect:
      case SeasonRewardType.cosmeticFragment:
        final result = await CosmeticsService.instance.unlockItem(
          itemId: milestone.rewardId,
          sourceType: 'season',
          sourceEvent: milestone.id,
        );
        // result is null if already owned — that's fine, not an error.
        debugPrint(
          '[SeasonService] milestone ${milestone.id}: '
          'granted ${milestone.rewardId} '
          '(already_owned=${result == null})',
        );
        return true;

      case SeasonRewardType.badge:
        // Badges are tracked in SeasonProgress — no separate persistence path.
        return true;
    }
  }

  // ── Season reset ───────────────────────────────────────────────

  /// Archives earned badge IDs from [expiredProgress] into the progress for
  /// [nextSeasonId]. Owned cosmetics are preserved automatically because they
  /// live in the CosmeticsService inventory.
  Future<SeasonProgress> resetForNewSeason({
    required SeasonProgress expiredProgress,
    required String nextSeasonId,
  }) async {
    // Collect badge IDs that were legitimately earned in the expired season.
    final allArchived = {
      ...expiredProgress.archivedBadgeIds,
    };

    // Any badge milestones that were claimed get archived.
    // (We don't fabricate badge IDs for unclaimed milestones.)
    final newProgress = SeasonProgress(
      seasonId: nextSeasonId,
      userId: expiredProgress.userId,
      earnedXp: 0,
      claimedMilestoneIds: const {},
      archivedBadgeIds: allArchived,
      appliedDailyRunTransactionIds: const {},
    );
    await saveProgress(newProgress);
    return newProgress;
  }

  // ── Season XP per Daily Run ────────────────────────────────────

  /// Returns the season XP gained for completing a Daily Run.
  ///
  /// Base: 30 XP. Multiplied by [streakMultiplier] (same value exposed by
  /// [DailyRunProvider.displayedXpMultiplier]).
  int dailyRunSeasonXp(double streakMultiplier) {
    final base = 30;
    return (base * streakMultiplier).round().clamp(30, 90);
  }

  // ── Private helpers ────────────────────────────────────────────

  String _progressKey(String userId, String seasonId) =>
      '$_progressKeyPrefix$userId.$seasonId';

  Future<void> _cacheSeasonLocally(Season season) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedSeasonKey, jsonEncode(season.toJson()));
    } catch (e) {
      debugPrint('[SeasonService] cache season failed: $e');
    }
  }

  Future<Season?> _loadCachedSeason() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedSeasonKey);
      if (raw == null) return null;
      return Season.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (e) {
      debugPrint('[SeasonService] load cached season failed: $e');
      return null;
    }
  }

  // ── Local quarter-based catalog ────────────────────────────────
  //
  // Seasons map to calendar quarters.  Dates are derived from [now] so there
  // are no hardcoded values that "break later" — each quarter produces a
  // predictable but dynamically-computed Season.

  Season _quarterSeason(DateTime now) {
    final quarter = ((now.month - 1) ~/ 3) + 1;
    final year = now.year;

    final (String id, String name, String theme, int startMonth, int endMonth) =
        switch (quarter) {
      1 => (
          'season_q1_$year',
          'Arctic Expedition',
          'arctic',
          1,
          4,
        ),
      2 => (
          'season_q2_$year',
          'Math Olympiad',
          'olympiad',
          4,
          7,
        ),
      3 => (
          'season_q3_$year',
          'Galaxy Quest',
          'galaxy',
          7,
          10,
        ),
      _ => (
          'season_q4_$year',
          'Winter Festival',
          'winter',
          10,
          1,
        ),
    };

    final startAt = DateTime(year, startMonth);
    // Q4 ends in January of the following year.
    final endAt = quarter == 4
        ? DateTime(year + 1, 1)
        : DateTime(year, endMonth);

    return Season(
      seasonId: id,
      name: name,
      theme: theme,
      startAt: startAt,
      endAt: endAt,
      featuredLegendaryCosmeticId: _featuredCosmeticForTheme(theme),
      milestones: _milestonesForSeason(id, theme),
      totalXpGoal: 500,
    );
  }

  String _featuredCosmeticForTheme(String theme) {
    switch (theme) {
      case 'olympiad':
        return 'frame_olympiad';
      case 'galaxy':
        return 'frame_gold_laurel';
      default:
        return 'frame_gold_laurel';
    }
  }

  List<SeasonMilestone> _milestonesForSeason(String seasonId, String theme) {
    return [
      SeasonMilestone(
        id: '${seasonId}_m1',
        label: 'First steps',
        xpRequired: 100,
        rewardType: SeasonRewardType.cosmeticFragment,
        rewardId: 'effect_nova_trail',
        rewardLabel: 'Nova Trail Fragment',
        rarity: CosmeticRarity.rare,
      ),
      SeasonMilestone(
        id: '${seasonId}_m2',
        label: 'Getting serious',
        xpRequired: 200,
        rewardType: SeasonRewardType.cosmetic,
        rewardId: 'frame_comet',
        rewardLabel: 'Comet Frame',
        rarity: CosmeticRarity.rare,
      ),
      SeasonMilestone(
        id: '${seasonId}_m3',
        label: 'Halfway hero',
        xpRequired: 300,
        rewardType: SeasonRewardType.badge,
        rewardId: '${seasonId}_finisher_badge',
        rewardLabel: 'Season Finisher Badge',
        rarity: CosmeticRarity.epic,
      ),
      SeasonMilestone(
        id: '${seasonId}_m4',
        label: 'Almost legendary',
        xpRequired: 400,
        rewardType: SeasonRewardType.cosmetic,
        rewardId: 'frame_blue_glow',
        rewardLabel: 'Blue Glow Frame',
        rarity: CosmeticRarity.epic,
      ),
      SeasonMilestone(
        id: '${seasonId}_m5',
        label: 'Season champion',
        xpRequired: 500,
        rewardType: SeasonRewardType.cosmetic,
        rewardId: _featuredCosmeticForTheme(theme),
        rewardLabel: _legendaryNameForTheme(theme),
        rarity: CosmeticRarity.legendary,
      ),
    ];
  }

  String _legendaryNameForTheme(String theme) {
    switch (theme) {
      case 'olympiad':
        return 'Olympiad Frame';
      default:
        return 'Gold Laurel Frame';
    }
  }

  // ── Test helper ────────────────────────────────────────────────

  /// Builds a [Season] with custom dates. Intended for widget / unit tests.
  @visibleForTesting
  static Season buildTestSeason({
    String seasonId = 'season_test',
    String name = 'Test Season',
    String theme = 'test',
    required DateTime startAt,
    required DateTime endAt,
    int totalXpGoal = 500,
  }) {
    return Season(
      seasonId: seasonId,
      name: name,
      theme: theme,
      startAt: startAt,
      endAt: endAt,
      featuredLegendaryCosmeticId: 'frame_gold_laurel',
      milestones: [
        SeasonMilestone(
          id: '${seasonId}_m1',
          label: 'First steps',
          xpRequired: 100,
          rewardType: SeasonRewardType.cosmetic,
          rewardId: 'frame_comet',
          rewardLabel: 'Comet Frame',
          rarity: CosmeticRarity.rare,
        ),
        SeasonMilestone(
          id: '${seasonId}_m2',
          label: 'Season champion',
          xpRequired: totalXpGoal,
          rewardType: SeasonRewardType.cosmetic,
          rewardId: 'frame_gold_laurel',
          rewardLabel: 'Gold Laurel Frame',
          rarity: CosmeticRarity.legendary,
        ),
      ],
      totalXpGoal: totalXpGoal,
    );
  }
}
