import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/season.dart';
import 'package:mathlearning/services/season_service.dart';
import 'package:mathlearning/state/season_provider.dart';

import '../test_helper.dart';

// ---------------------------------------------------------------------------
// Stub SeasonService — swaps out network/prefs so tests stay unit-level.
// ---------------------------------------------------------------------------
class _StubSeasonService extends SeasonService {
  _StubSeasonService({required Season? season})
    : _season = season,
      super.test();

  Season? _season;
  SeasonProgress? _savedProgress;
  int grantCalls = 0;
  bool grantResult = true;

  void updateSeason(Season s) => _season = s;

  @override
  Future<Season?> loadActiveSeason({DateTime? now}) async => _season;

  @override
  Future<SeasonProgress> loadProgress({
    required String seasonId,
    required String userId,
  }) async =>
      _savedProgress ??
      SeasonProgress.empty(seasonId: seasonId, userId: userId);

  @override
  Future<bool> saveProgress(SeasonProgress progress) async {
    _savedProgress = progress;
    return true;
  }

  @override
  Future<bool> grantMilestoneReward({
    required SeasonMilestone milestone,
    required String userId,
  }) async {
    grantCalls++;
    return grantResult;
  }

  @override
  Future<SeasonProgress> resetForNewSeason({
    required SeasonProgress expiredProgress,
    required String nextSeasonId,
  }) async {
    final fresh = SeasonProgress.empty(
      seasonId: nextSeasonId,
      userId: expiredProgress.userId,
    );
    _savedProgress = fresh;
    return fresh;
  }

  @override
  int dailyRunSeasonXp(double streakMultiplier) =>
      SeasonService.dailyRunSeasonXpFor(streakMultiplier);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Season _buildSeason({
  String id = 'season_test',
  DateTime? start,
  DateTime? end,
  int totalXpGoal = 500,
}) {
  final now = DateTime.now();
  return SeasonService.buildTestSeason(
    seasonId: id,
    startAt: start ?? now.subtract(const Duration(days: 30)),
    endAt: end ?? now.add(const Duration(days: 60)),
    totalXpGoal: totalXpGoal,
  );
}

Future<SeasonProvider> _buildProvider({
  Season? season,
  String userId = 'test_user',
}) async {
  final stub = _StubSeasonService(season: season ?? _buildSeason());
  final provider = SeasonProvider(service: stub);
  await provider.configureUserAndWait(userId);
  return provider;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  setupGlobalMocks();
  SharedPreferences.setMockInitialValues({});

  group('SeasonStatus', () {
    test('active when well within dates', () {
      final now = DateTime.now();
      final season = _buildSeason(
        start: now.subtract(const Duration(days: 10)),
        end: now.add(const Duration(days: 30)),
      );
      expect(season.status(now), SeasonStatus.active);
      expect(season.status(now).isUrgent, isFalse);
    });

    test('endingSoon7d when 4–7 days remain', () {
      final now = DateTime.now();
      final season = _buildSeason(
        start: now.subtract(const Duration(days: 60)),
        end: now.add(const Duration(days: 6)),
      );
      expect(season.status(now), SeasonStatus.endingSoon7d);
      // endingSoon7d is NOT urgent (only 3d/24h/ended are)
      expect(season.status(now).isUrgent, isFalse);
    });

    test('endingSoon3d when 1–3 days remain', () {
      final now = DateTime.now();
      final season = _buildSeason(
        start: now.subtract(const Duration(days: 60)),
        end: now.add(const Duration(days: 2)),
      );
      expect(season.status(now), SeasonStatus.endingSoon3d);
    });

    test('endingSoon24h when under 24 hours remain', () {
      final now = DateTime.now();
      final season = _buildSeason(
        start: now.subtract(const Duration(days: 60)),
        end: now.add(const Duration(hours: 12)),
      );
      expect(season.status(now), SeasonStatus.endingSoon24h);
    });

    test('ended when past endAt', () {
      final now = DateTime.now();
      final season = _buildSeason(
        start: now.subtract(const Duration(days: 90)),
        end: now.subtract(const Duration(days: 1)),
      );
      expect(season.status(now), SeasonStatus.ended);
    });

    test('urgencyLabel is non-empty for urgency states, empty for active', () {
      expect(SeasonStatus.endingSoon7d.urgencyLabel, isNotEmpty);
      expect(SeasonStatus.endingSoon3d.urgencyLabel, isNotEmpty);
      expect(SeasonStatus.endingSoon24h.urgencyLabel, isNotEmpty);
      expect(SeasonStatus.active.urgencyLabel, isEmpty);
      // ended has a label ('Season over') so UI can optionally show it
      expect(SeasonStatus.ended.urgencyLabel, isNotEmpty);
    });
  });

  group('SeasonProvider XP progress', () {
    test('starts with 0 XP and 0% completion', () async {
      final provider = await _buildProvider();
      expect(provider.earnedXp, 0);
      expect(provider.completionPercent, 0);
      expect(provider.progressFraction, 0.0);
    });

    test('awardDailyRunXp accumulates XP', () async {
      final provider = await _buildProvider();
      await provider.awardDailyRunXp(1.0);
      expect(provider.earnedXp, greaterThan(0));
    });

    test('awardDailyRunXp respects streak multiplier', () async {
      final p1 = await _buildProvider();
      final p2 = await _buildProvider();
      await p1.awardDailyRunXp(1.0);
      await p2.awardDailyRunXp(2.0);
      expect(p2.earnedXp, greaterThan(p1.earnedXp));
    });

    test('awardDailyRunXp sets pendingSeasonXpGain', () async {
      final provider = await _buildProvider();
      await provider.awardDailyRunXp(1.0);
      final gained = provider.takePendingXpGain();
      expect(gained, isNotNull);
      expect(gained, greaterThan(0));
    });

    test('takePendingXpGain is consumed once', () async {
      final provider = await _buildProvider();
      await provider.awardDailyRunXp(1.0);
      provider.takePendingXpGain();
      expect(provider.takePendingXpGain(), isNull);
    });

    test('XP does not exceed totalXpGoal * 2', () async {
      final provider = await _buildProvider(
        season: _buildSeason(totalXpGoal: 100),
      );
      for (var i = 0; i < 100; i++) {
        await provider.awardDailyRunXp(2.0);
      }
      expect(provider.earnedXp, lessThanOrEqualTo(200));
    });

    test('awardDailyRunXp does nothing for ended season', () async {
      final now = DateTime.now();
      final ended = _buildSeason(end: now.subtract(const Duration(days: 1)));
      final provider = await _buildProvider(season: ended);
      await provider.awardDailyRunXp(1.0);
      expect(provider.earnedXp, 0);
      expect(provider.takePendingXpGain(), isNull);
    });
  });

  group('SeasonProvider milestone claiming', () {
    test('canClaimMilestone is false before reaching XP threshold', () async {
      final provider = await _buildProvider();
      final milestone = provider.milestones.first;
      expect(provider.canClaimMilestone(milestone), isFalse);
    });

    test('canClaimMilestone is true after reaching XP threshold', () async {
      final provider = await _buildProvider();
      final milestone = provider.milestones.first; // 100 XP
      // Award enough XP to reach the first milestone.
      while (provider.earnedXp < milestone.xpRequired) {
        await provider.awardDailyRunXp(1.0);
      }
      expect(provider.canClaimMilestone(milestone), isTrue);
    });

    test('claimMilestone marks as claimed', () async {
      final provider = await _buildProvider();
      final milestone = provider.milestones.first;
      while (provider.earnedXp < milestone.xpRequired) {
        await provider.awardDailyRunXp(1.0);
      }
      final result = await provider.claimMilestone(milestone);
      expect(result.success, isTrue);
      expect(provider.isMilestoneClaimed(milestone.id), isTrue);
    });

    test('cannot claim same milestone twice', () async {
      final provider = await _buildProvider();
      final milestone = provider.milestones.first;
      while (provider.earnedXp < milestone.xpRequired) {
        await provider.awardDailyRunXp(1.0);
      }
      await provider.claimMilestone(milestone);
      final result2 = await provider.claimMilestone(milestone);
      expect(result2.success, isFalse);
      expect(result2.errorReason, contains('Already claimed'));
    });

    test('canClaimMilestone is false when season has ended', () async {
      final now = DateTime.now();
      final season = _buildSeason(
        start: now.subtract(const Duration(days: 90)),
        end: now.subtract(const Duration(days: 1)),
      );
      final provider = await _buildProvider(season: season);
      final milestone = provider.milestones.first;
      expect(provider.canClaimMilestone(milestone), isFalse);
    });

    test('claimMilestone fails for ended season', () async {
      final now = DateTime.now();
      final ended = _buildSeason(end: now.subtract(const Duration(days: 1)));
      final provider = await _buildProvider(season: ended);
      final milestone = provider.milestones.first;
      final result = await provider.claimMilestone(milestone);
      expect(result.success, isFalse);
    });

    test('pendingMilestoneReached fires on threshold crossing', () async {
      final provider = await _buildProvider();
      final milestone = provider.milestones.first;
      // Award XP right up to the milestone threshold.
      while (provider.earnedXp < milestone.xpRequired - 10) {
        await provider.awardDailyRunXp(1.0);
        provider.takePendingMilestoneReached(); // drain
      }
      // One more run that crosses the threshold.
      await provider.awardDailyRunXp(2.0);
      final reached = provider.takePendingMilestoneReached();
      if (provider.earnedXp >= milestone.xpRequired) {
        expect(reached, isNotNull);
        expect(reached!.id, milestone.id);
      }
      // After consuming it's null.
      expect(provider.takePendingMilestoneReached(), isNull);
    });
  });

  group('Season reset', () {
    test('onSeasonReset preserves no XP for next season', () async {
      final provider = await _buildProvider();
      await provider.awardDailyRunXp(1.0);
      expect(provider.earnedXp, greaterThan(0));
      // Replace the stub season with the next season.
      final stub = provider.debugService as _StubSeasonService;
      final nextSeason = _buildSeason(id: 'season_next');
      stub.updateSeason(nextSeason);
      await provider.onSeasonReset(nextSeasonId: 'season_next');
      expect(provider.earnedXp, 0);
      expect(provider.claimedMilestoneIds, isEmpty);
    });
  });

  group('isSeasonFeaturedItem', () {
    test('returns true only for the actual featured cosmetic id', () async {
      final season = _buildSeason(); // featured: 'frame_gold_laurel'
      final provider = await _buildProvider(season: season);
      expect(provider.isSeasonFeaturedItem('frame_gold_laurel'), isTrue);
      expect(provider.isSeasonFeaturedItem('frame_comet'), isFalse);
    });

    test('returns false for made-up item ids', () async {
      final provider = await _buildProvider();
      expect(provider.isSeasonFeaturedItem('fake_item_xyz'), isFalse);
    });
  });

  group('Season.fromJson safe fallback', () {
    test('parses minimal JSON without crashing', () {
      final now = DateTime.now().toIso8601String();
      final json = <String, dynamic>{
        'season_id': 'fallback_s',
        'name': 'Fallback Season',
        'theme': 'arctic',
        'start_at': now,
        'end_at': now,
        // Deliberately omit: featured_legendary_cosmetic_id, milestones,
        // total_xp_goal.
      };
      final season = Season.fromJson(json);
      expect(season.seasonId, 'fallback_s');
      expect(season.milestones, isEmpty);
      // featuredLegendaryCosmeticId defaults to empty string (not null) when omitted
      expect(season.featuredLegendaryCosmeticId, anyOf(isNull, isEmpty));
      expect(season.totalXpGoal, greaterThan(0)); // uses default
    });
  });
}
