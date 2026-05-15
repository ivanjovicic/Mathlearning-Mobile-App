import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Sound events
// ---------------------------------------------------------------------------

enum SoundEffect {
  // Countdown / start-beat channel
  runStartTick,

  // Answer channel
  correctPing,
  fastHit,
  speedStreak,

  // Combo channel
  comboBurst,

  // Reward channel
  chestDrop,
  chestOpenBig,
  xpCollect,
  coinCollect,
  rareFragmentReveal,
  rewardClaim,
  stageCleared,
  finalGateUnlocked,
  finalGateWhoosh,
}

// ---------------------------------------------------------------------------
// Sound channels — one active cue per channel; max two active simultaneously
// ---------------------------------------------------------------------------

enum _SoundChannel { countdown, answer, combo, reward }

/// Per-event playback settings.
final class _SoundSpec {
  const _SoundSpec({
    required this.assetPath,
    required this.channel,
    this.fallbackPattern = const <({Duration delay, SystemSoundType sound})>[],
    this.cooldown = Duration.zero,
    this.haptic,
  });

  /// Relative asset path (under pubspec assets). Used by a future audio player.
  /// Keep the path even if the file does not exist yet — the service falls
  /// back silently.
  final String assetPath;

  /// Which concurrency channel this event belongs to.
  final _SoundChannel channel;

  /// SystemSound-based fallback for devices/platforms without real audio.
  final List<({Duration delay, SystemSoundType sound})> fallbackPattern;

  /// Minimum gap between successive plays of the same event.
  final Duration cooldown;

  /// Paired haptic, always gated by [SoundService._hapticsEnabled].
  final SoundHaptic? haptic;
}

// ---------------------------------------------------------------------------
// Haptic levels (unchanged API)
// ---------------------------------------------------------------------------

enum SoundHaptic { selection, lightImpact, mediumImpact }

// ---------------------------------------------------------------------------
// Master event table
// ---------------------------------------------------------------------------

const Map<SoundEffect, _SoundSpec> _kSpecs = {
  // ── Countdown ──────────────────────────────────────────────────────────
  SoundEffect.runStartTick: _SoundSpec(
    assetPath: 'assets/audio/ui/run_start_tick.wav',
    channel: _SoundChannel.countdown,
    fallbackPattern: [(delay: Duration.zero, sound: SystemSoundType.click)],
    cooldown: Duration(milliseconds: 110),
  ),

  // ── Answer ────────────────────────────────────────────────────────────
  SoundEffect.correctPing: _SoundSpec(
    assetPath: 'assets/audio/ui/correct_ping.wav',
    channel: _SoundChannel.answer,
    cooldown: Duration(milliseconds: 180),
    haptic: SoundHaptic.lightImpact, // haptic only for now; remove once
    // asset lands and per-answer haptic
    // policy is tightened.
  ),
  SoundEffect.fastHit: _SoundSpec(
    assetPath: 'assets/audio/ui/fast_hit.wav',
    channel: _SoundChannel.answer,
    cooldown: Duration(milliseconds: 200),
  ),
  SoundEffect.speedStreak: _SoundSpec(
    assetPath: 'assets/audio/ui/speed_streak.wav',
    channel: _SoundChannel.answer,
    cooldown: Duration(milliseconds: 200),
  ),

  // ── Combo ─────────────────────────────────────────────────────────────
  SoundEffect.comboBurst: _SoundSpec(
    assetPath: 'assets/audio/ui/combo_burst.wav',
    channel: _SoundChannel.combo,
    cooldown: Duration(milliseconds: 900),
  ),

  // ── Reward ────────────────────────────────────────────────────────────
  SoundEffect.chestDrop: _SoundSpec(
    assetPath: 'assets/audio/rewards/chest_drop.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 300),
  ),
  SoundEffect.chestOpenBig: _SoundSpec(
    assetPath: 'assets/audio/rewards/chest_open_big.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 1000),
    haptic: SoundHaptic.mediumImpact,
  ),
  SoundEffect.xpCollect: _SoundSpec(
    assetPath: 'assets/audio/rewards/xp_collect.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 180),
  ),
  SoundEffect.coinCollect: _SoundSpec(
    assetPath: 'assets/audio/rewards/coin_collect.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 180),
  ),
  SoundEffect.rareFragmentReveal: _SoundSpec(
    assetPath: 'assets/audio/rewards/rare_fragment_reveal.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 600),
    haptic: SoundHaptic.selection,
  ),
  SoundEffect.rewardClaim: _SoundSpec(
    assetPath: 'assets/audio/rewards/reward_claim.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 450),
    haptic: SoundHaptic.lightImpact,
  ),
  SoundEffect.stageCleared: _SoundSpec(
    assetPath: 'assets/audio/rewards/stage_cleared.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 300),
  ),
  SoundEffect.finalGateUnlocked: _SoundSpec(
    assetPath: 'assets/audio/rewards/final_gate_unlocked.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 400),
    haptic: SoundHaptic.lightImpact,
  ),
  SoundEffect.finalGateWhoosh: _SoundSpec(
    assetPath: 'assets/audio/rewards/final_gate_whoosh.wav',
    channel: _SoundChannel.reward,
    cooldown: Duration(milliseconds: 200),
  ),
};

// ---------------------------------------------------------------------------
// SoundService
// ---------------------------------------------------------------------------

/// Central audio/haptic façade for the Daily Run experience.
///
/// **Channel policy**:
/// - Each [SoundEffect] belongs to one [_SoundChannel].
/// - At most one cue plays per channel at any time (new cue cancels the old).
/// - At most **two** channels may be active simultaneously. If a third channel
///   fires while two are already active, the cue is dropped.
/// - The **reward** channel enforces an additional 150 ms minimum gap between
///   any two cues to prevent rapid-fire stacking.
///
/// **Mute / vibration**:
/// - [setMuted] gates all audio output, but **not** haptics.
/// - [setHapticsEnabled] gates all haptic output, including haptics that are
///   paired with sound events (called even when [isMuted] is true).
/// - Direct [HapticFeedback] calls elsewhere must be replaced with
///   [haptic] / [hapticForAnswer] so the vibration setting is always honored.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  // ── State ───────────────────────────────────────────────────────────────

  final ValueNotifier<bool> _muted = ValueNotifier<bool>(false);
  bool _hapticsEnabled = true;

  /// Per-event cooldown tracker.
  final Map<SoundEffect, DateTime> _lastPlayedAt = {};

  /// Per-channel: token that cancels the previous cue's pattern loop.
  final Map<_SoundChannel, int> _channelToken = {};

  /// Per-channel: are we currently playing something?
  final Set<_SoundChannel> _activeChannels = {};

  /// Last time ANY reward-channel cue started (for the 150 ms inter-cue gap).
  DateTime? _lastRewardCueAt;

  // ── Public getters ──────────────────────────────────────────────────────

  ValueListenable<bool> get mutedListenable => _muted;
  bool get isMuted => _muted.value;

  /// Map of event name → intended asset path. Useful for tooling / tests.
  Map<String, String> get eventAssetMap => {
    for (final e in _kSpecs.entries) e.key.name: e.value.assetPath,
  };

  // ── Settings ────────────────────────────────────────────────────────────

  void setMuted(bool muted) {
    if (_muted.value == muted) return;
    _muted.value = muted;
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  void toggleMuted() => setMuted(!isMuted);

  // ── Haptic-only API (for callers that only need vibration) ──────────────

  /// Fire a standalone haptic, gated by the vibration setting.
  Future<void> haptic(SoundHaptic haptic) => _playPairedHaptic(haptic);

  /// Convenience: correct-answer haptic (light impact) + correct_ping sound.
  Future<void> hapticForCorrectAnswer() async {
    await playCorrectPing();
  }

  /// Convenience: wrong-answer haptic (selection click), gated by settings.
  Future<void> hapticForWrongAnswer() async {
    await _playPairedHaptic(SoundHaptic.selection);
  }

  // ── Sound playback ──────────────────────────────────────────────────────

  /// Play [effect], respecting channel policy, cooldowns, and mute state.
  Future<void> play(SoundEffect effect) async {
    final spec = _kSpecs[effect];
    if (spec == null) return;

    if (_isThrottled(effect, spec.cooldown)) return;

    // ── Channel-concurrency check ──────────────────────────────────────
    if (!_canActivateChannel(spec.channel)) return;

    // ── Reward-channel inter-cue gap (150 ms) ─────────────────────────
    if (spec.channel == _SoundChannel.reward) {
      final last = _lastRewardCueAt;
      if (last != null &&
          DateTime.now().difference(last) < const Duration(milliseconds: 150)) {
        return;
      }
      _lastRewardCueAt = DateTime.now();
    }

    // ── Bump token to cancel previous cue on the same channel ─────────
    final token = (_channelToken[spec.channel] ?? 0) + 1;
    _channelToken[spec.channel] = token;
    _activeChannels.add(spec.channel);

    try {
      // Haptic always fires first regardless of mute.
      await _playPairedHaptic(spec.haptic);

      // Asset playback — hook for future audio player.
      // Currently a no-op (no audio package in pubspec yet).
      // When ready, call: await _playAsset(spec.assetPath);
      //
      // Fallback: SystemSound pattern (exists only for runStartTick).
      if (!isMuted && spec.fallbackPattern.isNotEmpty) {
        await _playPattern(
          spec.fallbackPattern,
          channel: spec.channel,
          token: token,
        );
      }
    } finally {
      // Release channel if the token still matches (i.e., we weren't preempted).
      if (_channelToken[spec.channel] == token) {
        _activeChannels.remove(spec.channel);
      }
    }
  }

  // ── Named convenience methods ───────────────────────────────────────────

  Future<void> playRunStartTick() => play(SoundEffect.runStartTick);
  Future<void> playCorrectPing() => play(SoundEffect.correctPing);
  Future<void> playFastHit() => play(SoundEffect.fastHit);
  Future<void> playSpeedStreak() => play(SoundEffect.speedStreak);
  Future<void> playComboBurst() => play(SoundEffect.comboBurst);
  Future<void> playChestDrop() => play(SoundEffect.chestDrop);
  Future<void> playChestOpenBig() => play(SoundEffect.chestOpenBig);
  Future<void> playCoinCollect() => play(SoundEffect.coinCollect);
  Future<void> playXpCollect() => play(SoundEffect.xpCollect);
  Future<void> playRareFragmentReveal() => play(SoundEffect.rareFragmentReveal);
  Future<void> playRewardClaim() => play(SoundEffect.rewardClaim);
  Future<void> playStageCleared() => play(SoundEffect.stageCleared);
  Future<void> playFinalGateUnlocked() => play(SoundEffect.finalGateUnlocked);
  Future<void> playFinalGateWhoosh() => play(SoundEffect.finalGateWhoosh);

  // ── Private helpers ─────────────────────────────────────────────────────

  /// Returns true if [channel] can start a new cue (max 2 active at once).
  bool _canActivateChannel(_SoundChannel channel) {
    if (_activeChannels.contains(channel)) {
      // Preempt: new cue takes over the channel (token bump in play() handles it).
      return true;
    }
    // Allow if fewer than 2 distinct channels active.
    return _activeChannels.length < 2;
  }

  bool _isThrottled(SoundEffect effect, Duration cooldown) {
    if (cooldown <= Duration.zero) return false;
    final now = DateTime.now();
    final previous = _lastPlayedAt[effect];
    if (previous != null && now.difference(previous) < cooldown) return true;
    _lastPlayedAt[effect] = now;
    return false;
  }

  Future<void> _playPairedHaptic(SoundHaptic? haptic) async {
    if (!_hapticsEnabled || haptic == null) return;
    try {
      switch (haptic) {
        case SoundHaptic.selection:
          await HapticFeedback.selectionClick();
        case SoundHaptic.lightImpact:
          await HapticFeedback.lightImpact();
        case SoundHaptic.mediumImpact:
          await HapticFeedback.mediumImpact();
      }
    } catch (error, stackTrace) {
      debugPrint('Haptic playback error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _playOne(SystemSoundType type) async {
    try {
      await SystemSound.play(type);
    } catch (error, stackTrace) {
      debugPrint('SystemSound playback error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _playPattern(
    List<({Duration delay, SystemSoundType sound})> pattern, {
    required _SoundChannel channel,
    required int token,
  }) async {
    var elapsed = Duration.zero;
    for (final step in pattern) {
      if (_channelToken[channel] != token || isMuted) return;

      final wait = step.delay - elapsed;
      if (wait > Duration.zero) await Future<void>.delayed(wait);

      if (_channelToken[channel] != token || isMuted) return;

      elapsed = step.delay;
      await _playOne(step.sound);
    }
  }
}
