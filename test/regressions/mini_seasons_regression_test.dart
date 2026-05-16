import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/season.dart';
import 'package:mathlearning/services/season_service.dart';
import 'package:mathlearning/state/season_provider.dart';

class _RegressionSeasonService extends SeasonService {
  _RegressionSeasonService({required Season? season})
    : _season = season,
      super.test();

  Season? _season;
  SeasonProgress? _savedProgress;
  Completer<Season?>? activeSeasonCompleter;
  int loadActiveSeasonCalls = 0;
  int failActiveSeasonLoads = 0;

  void updateSeason(Season season) => _season = season;

  @override
  Future<Season?> loadActiveSeason({DateTime? now}) async {
    loadActiveSeasonCalls += 1;
    if (activeSeasonCompleter != null) {
      return activeSeasonCompleter!.future;
    }
    if (failActiveSeasonLoads > 0) {
      failActiveSeasonLoads -= 1;
      throw StateError('loadActiveSeason failed');
    }
    return _season;
  }

  @override
  Future<SeasonProgress> loadProgress({
    required String seasonId,
    required String userId,
  }) async {
    return _savedProgress ??
        SeasonProgress.empty(seasonId: seasonId, userId: userId);
  }

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
    return true;
  }

  @override
  Future<SeasonProgress> resetForNewSeason({
    required SeasonProgress expiredProgress,
    required String nextSeasonId,
  }) async {
    final fresh = SeasonProgress.empty(
      seasonId: nextSeasonId,
      userId: expiredProgress.userId,
    ).copyWith(
      archivedBadgeIds: {
        ...expiredProgress.archivedBadgeIds,
      },
    );
    _savedProgress = fresh;
    return fresh;
  }

  @override
  int dailyRunSeasonXp(double streakMultiplier) =>
      SeasonService.dailyRunSeasonXpFor(streakMultiplier);
}

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
  final stub = _RegressionSeasonService(season: season ?? _buildSeason());
  final provider = SeasonProvider(service: stub);
  await provider.configureUserAndWait(userId);
  return provider;
}

String _seasonProgressKey(String userId, String seasonId) =>
    'season_progress.v1.$userId.$seasonId';

String _pendingAwardKey(String userId) =>
    'season_pending_daily_run_award.v1.$userId';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('awardDailyRunXp waits for an in-flight load before applying', () async {
    final season = _buildSeason();
    final stub = _RegressionSeasonService(season: season)
      ..activeSeasonCompleter = Completer<Season?>();
    final provider = SeasonProvider(service: stub);

    provider.configureUser('user-1');
    await Future<void>.delayed(Duration.zero);

    final awardFuture = provider.awardDailyRunXp(1.0);
    await Future<void>.delayed(Duration.zero);
    stub.activeSeasonCompleter!.complete(season);

    final result = await awardFuture;

    expect(result.applied, isTrue);
    expect(provider.earnedXp, greaterThan(0));
    expect(stub.loadActiveSeasonCalls, greaterThanOrEqualTo(1));
  });

  test('awardDailyRunXp retries once when the initial load fails', () async {
    final season = _buildSeason();
    final stub = _RegressionSeasonService(season: season)..failActiveSeasonLoads = 1;
    final provider = SeasonProvider(service: stub);

    provider.configureUser('user-1');
    final result = await provider.awardDailyRunXp(1.0);

    expect(result.applied, isTrue);
    expect(provider.earnedXp, greaterThan(0));
    expect(stub.loadActiveSeasonCalls, 2);
  });

  test('pending season XP applies after restart exactly once', () async {
    final season = _buildSeason();
    final userId = 'user-1';
    final xpGain = SeasonService.dailyRunSeasonXpFor(1.0);
    final txId = 'season_daily_run_user-1_pending';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingAwardKey(userId),
      jsonEncode({
        'transactionId': txId,
        'userId': userId,
        'seasonId': season.seasonId,
        'xpGain': xpGain,
        'createdAtUtc': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    await prefs.setString(
      _seasonProgressKey(userId, season.seasonId),
      jsonEncode(
        SeasonProgress.empty(seasonId: season.seasonId, userId: userId)
            .toJson(),
      ),
    );

    final restarted = await _buildProvider(season: season, userId: userId);

    expect(restarted.earnedXp, xpGain);
    expect(restarted.progress?.appliedDailyRunTransactionIds, contains(txId));

    await restarted.reload();
    expect(restarted.earnedXp, xpGain);
  });

  test('expired reward cannot be claimed', () async {
    final now = DateTime.now();
    final ended = _buildSeason(end: now.subtract(const Duration(days: 1)));
    final provider = await _buildProvider(season: ended);
    final milestone = provider.milestones.first;

    final result = await provider.claimMilestone(milestone);

    expect(result.success, isFalse);
    expect(provider.isMilestoneClaimed(milestone.id), isFalse);
  });

  test('season reset preserves archived ownership and clears replay ids', () async {
    final season = _buildSeason();
    final service = _RegressionSeasonService(season: season);
    final current = SeasonProgress(
      seasonId: season.seasonId,
      userId: 'user-2',
      earnedXp: 120,
      claimedMilestoneIds: const {'milestone_1'},
      archivedBadgeIds: const {'badge_gold'},
      appliedDailyRunTransactionIds: const {'daily_run_tx_1'},
    );

    final next = await service.resetForNewSeason(
      expiredProgress: current,
      nextSeasonId: 'season_next',
    );

    expect(next.seasonId, 'season_next');
    expect(next.archivedBadgeIds, contains('badge_gold'));
    expect(next.appliedDailyRunTransactionIds, isEmpty);
  });
}
