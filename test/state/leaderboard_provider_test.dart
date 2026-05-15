import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/services/leaderboard_api_service.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';

class _FakeLeaderboardApiService extends LeaderboardApiService {
  LeaderboardResponse? leaderboardResponse;
  SchoolLeaderboardFeed? schoolResponse;
  List<RivalLeaderboardEntry>? rivalsResponse;
  Object? leaderboardError;
  Object? schoolError;
  Object? rivalsError;
  String? lastLeaderboardPeriod;
  String? lastSchoolPeriod;
  String? lastRivalsPeriod;

  @override
  Future<LeaderboardResponse?> fetchLeaderboard({
    required String scope,
    required String period,
    int limit = 50,
    String? cursor,
  }) async {
    lastLeaderboardPeriod = period;
    if (leaderboardError != null) {
      throw leaderboardError!;
    }
    return leaderboardResponse;
  }

  @override
  Future<SchoolLeaderboardFeed?> fetchSchoolLeaderboard({
    required String period,
    int limit = 50,
    String? cursor,
  }) async {
    lastSchoolPeriod = period;
    if (schoolError != null) {
      throw schoolError!;
    }
    return schoolResponse;
  }

  @override
  Future<List<RivalLeaderboardEntry>?> fetchRivals({
    required String period,
  }) async {
    lastRivalsPeriod = period;
    if (rivalsError != null) {
      throw rivalsError!;
    }
    return rivalsResponse;
  }
}

void main() {
  group('LeaderboardProvider', () {
    test('switching period reloads users leaderboard and rivals', () async {
      final api = _FakeLeaderboardApiService()
        ..leaderboardResponse = const LeaderboardResponse(
          items: <LeaderboardItem>[
            LeaderboardItem(
              rank: 1,
              userId: 1,
              displayName: 'Ava',
              score: 220,
              streakDays: 10,
            ),
          ],
          me: null,
          nextCursor: null,
        )
        ..rivalsResponse = const <RivalLeaderboardEntry>[
          RivalLeaderboardEntry(
            rank: 4,
            userId: 4,
            displayName: 'Mia',
            score: 170,
            streakDays: 5,
          ),
        ];
      final provider = LeaderboardProvider(api: api);

      await provider.changePeriod(
        LeaderboardPeriod.month,
        board: LeaderboardBoard.users,
      );

      expect(provider.currentPeriod, LeaderboardPeriod.month);
      expect(api.lastLeaderboardPeriod, 'month');
      expect(api.lastRivalsPeriod, 'month');
      expect(provider.itemsFor(LeaderboardScope.global), hasLength(1));
      expect(provider.rivals, hasLength(1));
    });

    test('loads school leaderboard entries', () async {
      final api = _FakeLeaderboardApiService()
        ..schoolResponse = const SchoolLeaderboardFeed(
          items: <SchoolLeaderboardEntry>[
            SchoolLeaderboardEntry(
              rank: 1,
              schoolId: 99,
              schoolName: 'Math High',
              totalScore: 9000,
              members: 120,
            ),
          ],
          currentSchool: SchoolLeaderboardEntry(
            rank: 1,
            schoolId: 99,
            schoolName: 'Math High',
            totalScore: 9000,
            members: 120,
          ),
          nextCursor: null,
        );
      final provider = LeaderboardProvider(api: api);

      await provider.reloadSchoolLeaderboard();

      expect(api.lastSchoolPeriod, 'week');
      expect(provider.schoolItems.single.schoolName, 'Math High');
      expect(provider.currentSchoolEntry?.schoolId, 99);
    });

    test('stores errors when user leaderboard API throws', () async {
      final api = _FakeLeaderboardApiService()
        ..leaderboardError = Exception('boom');
      final provider = LeaderboardProvider(api: api);

      await provider.reloadScope(LeaderboardScope.global);

      expect(provider.errorFor(LeaderboardScope.global), isA<Exception>());
    });

    test('stores errors when rivals API throws', () async {
      final api = _FakeLeaderboardApiService()
        ..rivalsError = Exception('rivals failed');
      final provider = LeaderboardProvider(api: api);

      await provider.fetchRivals();

      expect(provider.rivalsError, isA<Exception>());
    });
  });
}
