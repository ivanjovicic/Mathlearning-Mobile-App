import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/chase_race.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/services/chase_race_service.dart';
import 'package:mathlearning/state/chase_race_provider.dart';

import '../test_helper.dart';

// ── Stub service ─────────────────────────────────────────────────────────────

class _StubChaseRaceService extends ChaseRaceService {
  _StubChaseRaceService({this.race}) : super.test();

  ChaseRace? race;
  int loadCalls = 0;

  @override
  Future<ChaseRace?> loadRace({
    required String itemId,
    required String userId,
  }) async {
    loadCalls++;
    return race;
  }

  @override
  Future<void> clearCache(String itemId) async {}
}

// ── Helpers ──────────────────────────────────────────────────────────────────

ChaseRaceEntry _entry({
  required String userId,
  required String displayName,
  int fragmentsOwned = 0,
  int fragmentsRequired = 5,
  int todayGained = 0,
  DateTime? completedAt,
}) {
  return ChaseRaceEntry(
    userId: userId,
    displayName: displayName,
    itemId: 'frame_comet',
    fragmentsOwned: fragmentsOwned,
    fragmentsRequired: fragmentsRequired,
    todayGained: todayGained,
    completedAt: completedAt,
  );
}

CosmeticTarget _target({
  String itemId = 'frame_comet',
  int owned = 2,
  int required = 5,
}) {
  return CosmeticTarget(
    targetCosmeticItemId: itemId,
    targetFragmentsOwned: owned,
    targetFragmentsRequired: required,
    targetRarity: CosmeticRarity.rare,
    targetItemName: 'Comet Frame',
  );
}

ChaseRace _raceWith(List<ChaseRaceEntry> participants) {
  return ChaseRace(
    itemId: 'frame_comet',
    itemName: 'Comet Frame',
    itemRarity: CosmeticRarity.rare,
    participants: ChaseRace.sortAndRankForTest(participants),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setupGlobalMocks();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Model: ranking ──────────────────────────────────────────────────────────

  group('ChaseRace ranking', () {
    test('completed entries ranked above incomplete ones', () {
      final entries = [
        _entry(userId: 'a', displayName: 'Alice', fragmentsOwned: 3),
        _entry(
          userId: 'b',
          displayName: 'Bob',
          fragmentsOwned: 5,
          completedAt: DateTime(2026, 5, 14),
        ),
        _entry(userId: 'c', displayName: 'Carol', fragmentsOwned: 4),
      ];
      final ranked = ChaseRace.sortAndRankForTest(entries);

      expect(ranked[0].userId, 'b'); // completed → rank 1
      expect(ranked[1].userId, 'c'); // 4 fragments → rank 2
      expect(ranked[2].userId, 'a'); // 3 fragments → rank 3
    });

    test('multiple completions ordered by completedAt ascending', () {
      final entries = [
        _entry(
          userId: 'a',
          displayName: 'Alice',
          fragmentsOwned: 5,
          completedAt: DateTime(2026, 5, 15, 12),
        ),
        _entry(
          userId: 'b',
          displayName: 'Bob',
          fragmentsOwned: 5,
          completedAt: DateTime(2026, 5, 15, 8),
        ),
      ];
      final ranked = ChaseRace.sortAndRankForTest(entries);

      expect(ranked[0].userId, 'b'); // earlier completedAt → rank 1
      expect(ranked[1].userId, 'a');
    });

    test('incomplete entries sorted by fragments descending', () {
      final entries = [
        _entry(userId: 'a', displayName: 'Alice', fragmentsOwned: 1),
        _entry(userId: 'b', displayName: 'Bob', fragmentsOwned: 4),
        _entry(userId: 'c', displayName: 'Carol', fragmentsOwned: 2),
      ];
      final ranked = ChaseRace.sortAndRankForTest(entries);

      expect(ranked[0].userId, 'b');
      expect(ranked[1].userId, 'c');
      expect(ranked[2].userId, 'a');
    });

    test('ranks are 1-based and sequential', () {
      final entries = [
        _entry(userId: 'a', displayName: 'Alice', fragmentsOwned: 3),
        _entry(userId: 'b', displayName: 'Bob', fragmentsOwned: 1),
        _entry(userId: 'c', displayName: 'Carol', fragmentsOwned: 5),
      ];
      final ranked = ChaseRace.sortAndRankForTest(entries);
      final ranks = ranked.map((e) => e.rank).toList();

      expect(ranks, [1, 2, 3]);
    });
  });

  // ── Model: helpers ──────────────────────────────────────────────────────────

  group('ChaseRace helpers', () {
    test('hasCompetitors is false with one participant', () {
      final race = _raceWith([_entry(userId: 'me', displayName: 'Me')]);
      expect(race.hasCompetitors, isFalse);
    });

    test('hasCompetitors is true with two or more participants', () {
      final race = _raceWith([
        _entry(userId: 'me', displayName: 'Me'),
        _entry(userId: 'other', displayName: 'Other'),
      ]);
      expect(race.hasCompetitors, isTrue);
    });

    test('firstFinisher is null when no one has completed', () {
      final race = _raceWith([
        _entry(userId: 'a', displayName: 'A', fragmentsOwned: 3),
        _entry(userId: 'b', displayName: 'B', fragmentsOwned: 2),
      ]);
      expect(race.firstFinisher, isNull);
    });

    test('firstFinisher returns the first completed entry', () {
      final race = _raceWith([
        _entry(
          userId: 'a',
          displayName: 'A',
          fragmentsOwned: 5,
          completedAt: DateTime(2026, 5, 16),
        ),
        _entry(userId: 'b', displayName: 'B', fragmentsOwned: 2),
      ]);
      expect(race.firstFinisher?.userId, 'a');
    });
  });

  // ── Model: fromJson ─────────────────────────────────────────────────────────

  group('ChaseRaceEntry.fromJson', () {
    test('parses snake_case keys', () {
      final json = {
        'user_id': 'u1',
        'display_name': 'Alice',
        'item_id': 'frame_comet',
        'fragments_owned': 3,
        'fragments_required': 5,
        'today_gained': 1,
      };
      final entry = ChaseRaceEntry.fromJson(json);

      expect(entry.userId, 'u1');
      expect(entry.displayName, 'Alice');
      expect(entry.fragmentsOwned, 3);
      expect(entry.fragmentsRequired, 5);
      expect(entry.todayGained, 1);
      expect(entry.completedAt, isNull);
    });

    test('parses camelCase keys', () {
      final json = {
        'userId': 'u2',
        'displayName': 'Bob',
        'itemId': 'frame_comet',
        'fragmentsOwned': 5,
        'fragmentsRequired': 5,
        'todayGained': 0,
        'completedAt': '2026-05-14T10:00:00.000Z',
      };
      final entry = ChaseRaceEntry.fromJson(json);

      expect(entry.userId, 'u2');
      expect(entry.isComplete, isTrue);
      expect(entry.completedAt, isNotNull);
    });

    test('clamps fragments_owned below zero', () {
      final json = {
        'user_id': 'u3',
        'display_name': 'Carol',
        'item_id': 'frame_comet',
        'fragments_owned': -5,
        'fragments_required': 5,
      };
      final entry = ChaseRaceEntry.fromJson(json);
      expect(entry.fragmentsOwned, 0);
    });

    test('defaults missing fields gracefully', () {
      final json = <String, dynamic>{};
      final entry = ChaseRaceEntry.fromJson(json);

      expect(entry.userId, isEmpty);
      expect(entry.fragmentsOwned, 0);
      expect(entry.fragmentsRequired, 5);
      expect(entry.todayGained, 0);
      expect(entry.completedAt, isNull);
    });
  });

  // ── Provider: no fake data ──────────────────────────────────────────────────

  group('ChaseRaceProvider — no fake data injection', () {
    test('race is null when backend unavailable and no cache', () async {
      final stub = _StubChaseRaceService(race: null);
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target());

      expect(provider.race, isNull);
      expect(provider.catchUpMessages, isEmpty);
    });

    test('catchUpMessages is empty when no race', () {
      final stub = _StubChaseRaceService(race: null);
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      expect(provider.catchUpMessages, isEmpty);
    });

    test('no network call when target is null', () async {
      final stub = _StubChaseRaceService(race: null);
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(null);

      expect(stub.loadCalls, 0);
      expect(provider.race, isNull);
    });
  });

  // ── Provider: race visibility ───────────────────────────────────────────────

  group('ChaseRaceProvider — race visibility', () {
    test('solo race (1 participant) does not show as race', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([_entry(userId: 'user1', displayName: 'Me')]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target());

      // The race exists but hasCompetitors is false.
      expect(provider.race, isNotNull);
      expect(provider.race!.hasCompetitors, isFalse);
    });

    test('race with 2+ participants shows as race', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(userId: 'user1', displayName: 'Me', fragmentsOwned: 2),
          _entry(userId: 'user2', displayName: 'Rival', fragmentsOwned: 3),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(owned: 2));

      expect(provider.race!.hasCompetitors, isTrue);
      expect(provider.race!.participants.length, 2);
    });
  });

  // ── Provider: race ranking updates ─────────────────────────────────────────

  group('ChaseRaceProvider — ranking updates', () {
    test('current user entry is merged from local CosmeticTarget', () async {
      // Backend reports user1 with 0 fragments, but local target says 3.
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(userId: 'user1', displayName: 'Me', fragmentsOwned: 0),
          _entry(userId: 'user2', displayName: 'Rival', fragmentsOwned: 3),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(owned: 4)); // local says 4

      final me = provider.myEntry;
      expect(me, isNotNull);
      expect(me!.fragmentsOwned, 4); // local data wins
    });

    test('local progress update re-ranks without network call', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(userId: 'user1', displayName: 'Me', fragmentsOwned: 1),
          _entry(userId: 'user2', displayName: 'Rival', fragmentsOwned: 3),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(owned: 1));
      final loadCallsBefore = stub.loadCalls;

      // Simulate daily run — local progress improves.
      provider.applyLocalProgressUpdate(_target(owned: 4));

      expect(stub.loadCalls, loadCallsBefore); // no extra network call
      expect(provider.myEntry?.fragmentsOwned, 4);
    });

    test('configureUser resets race state', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(userId: 'user1', displayName: 'Me', fragmentsOwned: 2),
          _entry(userId: 'user2', displayName: 'Rival', fragmentsOwned: 3),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');
      await provider.loadRaceForTarget(_target());

      expect(provider.race, isNotNull);

      provider.configureUser('user2');
      expect(provider.race, isNull);
    });
  });

  // ── Provider: catch-up messaging ────────────────────────────────────────────

  group('ChaseRaceProvider — catch-up messaging', () {
    test('You passed X today message — only when todayGained > 0 and ahead', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(
            userId: 'user1',
            displayName: 'Me',
            fragmentsOwned: 4,
            todayGained: 2,
          ),
          _entry(
            userId: 'user2',
            displayName: 'Rival',
            fragmentsOwned: 2,
            todayGained: 0,
          ),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(owned: 4));

      final messages = provider.catchUpMessages;
      expect(
        messages.any((m) => m.contains('passed') && m.contains('Rival')),
        isTrue,
      );
    });

    test('no pass message when user gained nothing today', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(
            userId: 'user1',
            displayName: 'Me',
            fragmentsOwned: 4,
            todayGained: 0,
          ),
          _entry(
            userId: 'user2',
            displayName: 'Rival',
            fragmentsOwned: 2,
            todayGained: 0,
          ),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(owned: 4));

      final messages = provider.catchUpMessages;
      expect(messages.any((m) => m.contains('passed')), isFalse);
    });

    test('1 fragment away message for competitor near completion', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(userId: 'user1', displayName: 'Me', fragmentsOwned: 2),
          _entry(
            userId: 'user2',
            displayName: 'Rival',
            fragmentsOwned: 4,
            fragmentsRequired: 5,
          ),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(owned: 2));

      final messages = provider.catchUpMessages;
      expect(
        messages.any(
          (m) =>
              m.contains('Rival') &&
              m.contains('1 fragment'),
        ),
        isTrue,
      );
    });

    test('fell behind message when user gained nothing and rival moved up', () async {
      // Rival already finished (completed) with todayGained > 0.
      // This prevents "N more runs" (rival is complete) and "almost done"
      // (rival is already past the finish line), so "fell behind" fires.
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(
            userId: 'user2',
            displayName: 'Rival',
            fragmentsOwned: 5,
            fragmentsRequired: 5,
            todayGained: 2,
            completedAt: DateTime(2026, 5, 14),
          ),
          _entry(
            userId: 'user1',
            displayName: 'Me',
            fragmentsOwned: 1,
            todayGained: 0,
          ),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(owned: 1));

      final messages = provider.catchUpMessages;
      expect(
        messages.any((m) => m.contains('fell behind') && m.contains('Rival')),
        isTrue,
      );
    });
  });

  // ── Provider: race completion ───────────────────────────────────────────────

  group('ChaseRaceProvider — race completion', () {
    test('isFirstFinisher returns true for the first completer', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(
            userId: 'user1',
            displayName: 'Me',
            fragmentsOwned: 5,
            completedAt: DateTime(2026, 5, 14, 8),
          ),
          _entry(
            userId: 'user2',
            displayName: 'Rival',
            fragmentsOwned: 5,
            completedAt: DateTime(2026, 5, 14, 12),
          ),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');
      await provider.loadRaceForTarget(_target(owned: 5));

      expect(provider.isFirstFinisher('user1'), isTrue);
      expect(provider.isFirstFinisher('user2'), isFalse);
    });

    test('isFirstFinisher returns false when no one has completed', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(userId: 'user1', displayName: 'Me', fragmentsOwned: 3),
          _entry(userId: 'user2', displayName: 'Rival', fragmentsOwned: 2),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');
      await provider.loadRaceForTarget(_target(owned: 3));

      expect(provider.isFirstFinisher('user1'), isFalse);
    });
  });

  // ── Provider: backend fallback safety ──────────────────────────────────────

  group('ChaseRaceProvider — backend fallback safety', () {
    test('debug service accessor returns the injected service', () {
      final stub = _StubChaseRaceService();
      final provider = ChaseRaceProvider(service: stub);
      expect(provider.debugService, same(stub));
    });

    test('different target item triggers new network call', () async {
      final stub = _StubChaseRaceService(race: null);
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(itemId: 'frame_comet'));
      await provider.loadRaceForTarget(_target(itemId: 'frame_galaxy'));

      expect(stub.loadCalls, 2);
    });

    test('same target item does not trigger extra network call', () async {
      final stub = _StubChaseRaceService(
        race: _raceWith([
          _entry(userId: 'user1', displayName: 'Me', fragmentsOwned: 2),
          _entry(userId: 'user2', displayName: 'Rival', fragmentsOwned: 3),
        ]),
      );
      final provider = ChaseRaceProvider(service: stub);
      provider.configureUser('user1');

      await provider.loadRaceForTarget(_target(owned: 2));
      await provider.loadRaceForTarget(_target(owned: 3)); // same itemId

      expect(stub.loadCalls, 1); // no second network call
    });
  });
}
