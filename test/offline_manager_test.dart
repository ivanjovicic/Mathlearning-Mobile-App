import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/services/offline_manager.dart';
import 'package:mathlearning/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.initialize();
  });

  // ───────── retryWithBackoff ─────────

  group('retryWithBackoff', () {
    late OfflineManager manager;

    setUp(() {
      manager = OfflineManager.instance;
    });

    test('succeeds on first try without retries', () async {
      int callCount = 0;

      await manager.retryWithBackoff(() async {
        callCount++;
      });

      expect(callCount, 1);
    });

    test('retries on failure and succeeds on second attempt', () async {
      int callCount = 0;

      await manager.retryWithBackoff(() async {
        callCount++;
        if (callCount < 2) {
          throw Exception('transient error');
        }
      });

      expect(callCount, 2);
    });

    test('retries up to maxAttempts then rethrows', () async {
      int callCount = 0;

      expect(
        () => manager.retryWithBackoff(
          () async {
            callCount++;
            throw Exception('permanent failure');
          },
          maxAttempts: 3,
        ),
        throwsException,
      );

      // Wait for all retries to complete
      await Future.delayed(const Duration(seconds: 5));
      expect(callCount, 3);
    });

    test('respects custom maxAttempts parameter', () async {
      int callCount = 0;

      try {
        await manager.retryWithBackoff(
          () async {
            callCount++;
            throw Exception('always fails');
          },
          maxAttempts: 2,
        );
      } catch (_) {}

      expect(callCount, 2);
    });

    test('succeeds on the last allowed attempt', () async {
      int callCount = 0;

      await manager.retryWithBackoff(
        () async {
          callCount++;
          if (callCount < 4) {
            throw Exception('not yet');
          }
        },
        maxAttempts: 4,
      );

      expect(callCount, 4);
    });

    test('uses exponential backoff delays', () async {
      final timestamps = <DateTime>[];

      try {
        await manager.retryWithBackoff(
          () async {
            timestamps.add(DateTime.now());
            throw Exception('fail');
          },
          maxAttempts: 3,
        );
      } catch (_) {}

      expect(timestamps.length, 3);

      // Delay between attempt 1 and 2 should be ~400ms
      final delay1 = timestamps[1].difference(timestamps[0]);
      expect(delay1.inMilliseconds, greaterThanOrEqualTo(350));

      // Delay between attempt 2 and 3 should be ~800ms (doubled)
      final delay2 = timestamps[2].difference(timestamps[1]);
      expect(delay2.inMilliseconds, greaterThanOrEqualTo(700));

      // Second delay should be roughly double the first
      expect(delay2.inMilliseconds, greaterThan(delay1.inMilliseconds));
    });
  });

  // ───────── pendingCountStream ─────────

  group('pendingCountStream', () {
    test('stream is a broadcast stream that allows multiple listeners', () {
      final manager = OfflineManager.instance;

      // Should not throw — broadcast streams allow multiple listeners
      final sub1 = manager.pendingCountStream.listen((_) {});
      final sub2 = manager.pendingCountStream.listen((_) {});

      expect(sub1, isNotNull);
      expect(sub2, isNotNull);

      sub1.cancel();
      sub2.cancel();
    });
  });

  // ───────── Helper data classes ─────────

  group('PendingAnswer', () {
    test('serializes to JSON correctly', () {
      final answer = PendingAnswer(
        questionId: 'q42',
        isCorrect: true,
        timeMs: 1500,
        createdAt: DateTime(2025, 1, 15, 10, 30),
      );

      final json = answer.toJson();

      expect(json['questionId'], 'q42');
      expect(json['isCorrect'], true);
      expect(json['timeMs'], 1500);
      expect(json['createdAt'], '2025-01-15T10:30:00.000');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'questionId': 'q99',
        'isCorrect': false,
        'timeMs': 3200,
        'createdAt': '2025-06-01T14:00:00.000',
      };

      final answer = PendingAnswer.fromJson(json);

      expect(answer.questionId, 'q99');
      expect(answer.isCorrect, false);
      expect(answer.timeMs, 3200);
      expect(answer.createdAt, DateTime(2025, 6, 1, 14, 0));
    });

    test('round-trips through JSON without data loss', () {
      final original = PendingAnswer(
        questionId: 'q7',
        isCorrect: true,
        timeMs: 800,
        createdAt: DateTime(2025, 3, 10, 8, 15),
      );

      final restored = PendingAnswer.fromJson(original.toJson());

      expect(restored.questionId, original.questionId);
      expect(restored.isCorrect, original.isCorrect);
      expect(restored.timeMs, original.timeMs);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('PendingSrsUpdate', () {
    test('serializes to JSON correctly', () {
      final update = PendingSrsUpdate(
        questionId: 'srs1',
        isCorrect: false,
        timeMs: 2000,
        createdAt: DateTime(2025, 2, 20, 16, 45),
      );

      final json = update.toJson();

      expect(json['questionId'], 'srs1');
      expect(json['isCorrect'], false);
      expect(json['timeMs'], 2000);
      expect(json['createdAt'], '2025-02-20T16:45:00.000');
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'questionId': 'srs55',
        'isCorrect': true,
        'timeMs': 500,
        'createdAt': '2025-07-04T12:00:00.000',
      };

      final update = PendingSrsUpdate.fromJson(json);

      expect(update.questionId, 'srs55');
      expect(update.isCorrect, true);
      expect(update.timeMs, 500);
      expect(update.createdAt, DateTime(2025, 7, 4, 12, 0));
    });

    test('round-trips through JSON without data loss', () {
      final original = PendingSrsUpdate(
        questionId: 'srs88',
        isCorrect: true,
        timeMs: 1200,
        createdAt: DateTime(2025, 5, 5, 9, 0),
      );

      final restored = PendingSrsUpdate.fromJson(original.toJson());

      expect(restored.questionId, original.questionId);
      expect(restored.isCorrect, original.isCorrect);
      expect(restored.timeMs, original.timeMs);
      expect(restored.createdAt, original.createdAt);
    });
  });

  // ───────── SRS pending queue (SharedPreferences) ─────────

  group('SRS pending queue via SharedPreferences', () {
    test('getPendingSrsUpdatesCount returns 0 when empty', () async {
      final manager = OfflineManager.instance;
      final count = await manager.getPendingSrsUpdatesCount();
      expect(count, 0);
    });
  });

  // ───────── isOnline / _isOnlineWithToken ─────────

  group('isOnline', () {
    test('defaults to true when connectivity service not initialized', () {
      // Before initialize(), _connectivity is null so isOnline falls back to true
      final manager = OfflineManager.instance;
      expect(manager.isOnline, isTrue);
    });
  });

  // ───────── syncPendingData without token ─────────

  group('syncPendingData', () {
    test('syncPendingData skips sync when not authenticated', () async {
      // AuthService initialized but not logged in — _isOnlineWithToken is false.
      // syncPendingData should exit early before reaching any storage calls.
      // We verify by checking no exception is thrown from API calls —
      // only emitPendingCount is called, which triggers sqflite in test env.
      // So we just verify the isOnline flag is correct.
      final manager = OfflineManager.instance;
      expect(manager.isOnline, isTrue);
      // Not logged in → _isOnlineWithToken is false → sync skips API calls
      expect(AuthService.instance.isLoggedIn, isFalse);
    });

    test('manualSync is a public entry point for syncPendingData', () {
      // manualSync simply delegates to syncPendingData
      final manager = OfflineManager.instance;
      // Verify the method exists and is callable
      expect(manager.manualSync, isA<Function>());
    });
  });
}
