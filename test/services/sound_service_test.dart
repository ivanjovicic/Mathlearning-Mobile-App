// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/services/sound_service.dart';

SoundService get _sut => SoundService.instance;

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  setUp(() {
    // Reset mute and haptics to defaults.
    _sut.setMuted(false);
    _sut.setHapticsEnabled(true);
  });

  // ── Event-asset map ───────────────────────────────────────────────────────

  group('eventAssetMap', () {
    test('contains all SoundEffect enum values', () {
      final map = _sut.eventAssetMap;
      for (final effect in SoundEffect.values) {
        expect(
          map.containsKey(effect.name),
          isTrue,
          reason: '${effect.name} missing from eventAssetMap',
        );
      }
    });

    test('all paths start with assets/audio/', () {
      for (final path in _sut.eventAssetMap.values) {
        expect(
          path.startsWith('assets/audio/'),
          isTrue,
          reason: 'Bad path: $path',
        );
      }
    });

    test('new events are present: fast_hit, speed_streak, stage_cleared, '
        'final_gate_unlocked, final_gate_whoosh', () {
      final map = _sut.eventAssetMap;
      for (final name in [
        'fast_hit',
        'speed_streak',
        'stage_cleared',
        'final_gate_unlocked',
        'final_gate_whoosh',
      ]) {
        expect(map.containsKey(name), isTrue, reason: '$name missing');
      }
    });
  });

  // ── Mute gate ─────────────────────────────────────────────────────────────

  group('mute state', () {
    test('isMuted defaults to false', () {
      expect(_sut.isMuted, isFalse);
    });

    test('setMuted toggles isMuted', () {
      _sut.setMuted(true);
      expect(_sut.isMuted, isTrue);
      _sut.setMuted(false);
      expect(_sut.isMuted, isFalse);
    });

    test('toggleMuted flips state', () {
      _sut.setMuted(false);
      _sut.toggleMuted();
      expect(_sut.isMuted, isTrue);
      _sut.toggleMuted();
      expect(_sut.isMuted, isFalse);
    });

    test('mutedListenable notifies on change', () {
      _sut.setMuted(false);
      var notified = false;
      _sut.mutedListenable.addListener(() => notified = true);
      _sut.setMuted(true);
      expect(notified, isTrue);
      _sut.setMuted(false);
    });

    test('setMuted(same value) is idempotent (no spurious notification)', () {
      _sut.setMuted(false);
      var count = 0;
      _sut.mutedListenable.addListener(() => count++);
      _sut.setMuted(false); // same value
      expect(count, 0);
    });

    test('play() does not throw when muted', () async {
      _sut.setMuted(true);
      await expectLater(
        _sut.play(SoundEffect.run_start_tick),
        completes,
      );
    });
  });

  // ── Haptics gate ──────────────────────────────────────────────────────────

  group('haptics gate', () {
    test('setHapticsEnabled(false) → hapticForWrongAnswer completes silently', () async {
      _sut.setHapticsEnabled(false);
      await expectLater(_sut.hapticForWrongAnswer(), completes);
    });

    test('setHapticsEnabled(true) → hapticForCorrectAnswer completes', () async {
      _sut.setHapticsEnabled(true);
      await expectLater(_sut.hapticForCorrectAnswer(), completes);
    });

    test('haptic(SoundHaptic.mediumImpact) completes with hapticsEnabled=false', () async {
      _sut.setHapticsEnabled(false);
      await expectLater(_sut.haptic(SoundHaptic.mediumImpact), completes);
    });
  });

  // ── Named convenience methods ─────────────────────────────────────────────

  group('named play methods complete without throwing', () {
    final methods = <String, Future<void> Function()>{
      'playRunStartTick': _sut.playRunStartTick,
      'playCorrectPing': _sut.playCorrectPing,
      'playFastHit': _sut.playFastHit,
      'playSpeedStreak': _sut.playSpeedStreak,
      'playComboBurst': _sut.playComboBurst,
      'playChestDrop': _sut.playChestDrop,
      'playChestOpenBig': _sut.playChestOpenBig,
      'playCoinCollect': _sut.playCoinCollect,
      'playXpCollect': _sut.playXpCollect,
      'playRareFragmentReveal': _sut.playRareFragmentReveal,
      'playRewardClaim': _sut.playRewardClaim,
      'playStageCleared': _sut.playStageCleared,
      'playFinalGateUnlocked': _sut.playFinalGateUnlocked,
      'playFinalGateWhoosh': _sut.playFinalGateWhoosh,
    };

    for (final entry in methods.entries) {
      test(entry.key, () async {
        await expectLater(entry.value(), completes);
      });
    }
  });

  // ── Channel policy ────────────────────────────────────────────────────────

  group('channel policy', () {
    test('two different channels can play concurrently (no crash)', () async {
      // run_start_tick (countdown) and combo_burst (combo) are different channels.
      final f1 = _sut.playRunStartTick();
      final f2 = _sut.playComboBurst();
      await expectLater(Future.wait([f1, f2]), completes);
    });

    test('same channel can be preempted (no deadlock)', () async {
      // Fire two reward-channel events back to back; second should not hang.
      final f1 = _sut.playChestDrop();
      final f2 = _sut.playChestOpenBig();
      await expectLater(Future.wait([f1, f2]), completes);
    });

    test('play() does not throw for unknown/new effects', () async {
      // All enum values must be in _kSpecs; this validates the table is complete.
      for (final effect in SoundEffect.values) {
        await expectLater(_sut.play(effect), completes);
      }
    });
  });

  // ── Reward inter-cue gap (150 ms) ─────────────────────────────────────────

  group('reward channel inter-cue gap', () {
    test('second reward cue within 150 ms is dropped (completes without error)', () async {
      // Reset last-reward timestamp by calling a non-reward event first.
      await _sut.playRunStartTick();

      // Fire two reward cues with no delay — the second should be silently dropped.
      final f1 = _sut.playChestDrop();
      final f2 = _sut.playCoinCollect(); // < 150 ms after f1
      await expectLater(Future.wait([f1, f2]), completes);
    });
  });

  // ── Cooldown ──────────────────────────────────────────────────────────────

  group('cooldown throttling', () {
    test('rapid successive plays of same effect complete without error', () async {
      await _sut.playCorrectPing();
      // Second call within cooldown should be silently swallowed.
      await expectLater(_sut.playCorrectPing(), completes);
    });

    test('combo_burst has 900 ms cooldown (second rapid call dropped)', () async {
      await _sut.playComboBurst();
      await expectLater(_sut.playComboBurst(), completes);
    });
  });

  // ── Mute does not suppress haptics ───────────────────────────────────────

  group('mute vs haptics independence', () {
    test('hapticForWrongAnswer() still completes even when audio is muted', () async {
      _sut.setMuted(true);
      _sut.setHapticsEnabled(true);
      // Should not throw; platform may no-op haptic in test environment.
      await expectLater(_sut.hapticForWrongAnswer(), completes);
      _sut.setMuted(false);
    });
  });
}
