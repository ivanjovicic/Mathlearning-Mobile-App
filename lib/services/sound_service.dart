import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SoundEffect {
  run_start_tick,
  correct_ping,
  combo_burst,
  chest_drop,
  chest_open_big,
  coin_collect,
  xp_collect,
  rare_fragment_reveal,
  reward_claim,
}

enum SoundHaptic {
  selection,
  lightImpact,
  mediumImpact,
}

final class _SoundSpec {
  const _SoundSpec({
    required this.assetPath,
    this.fallbackPattern = const <({Duration delay, SystemSoundType sound})>[],
    this.cooldown = Duration.zero,
    this.haptic,
  });

  final String assetPath;
  final List<({Duration delay, SystemSoundType sound})> fallbackPattern;
  final Duration cooldown;
  final SoundHaptic? haptic;
}

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  static const Map<SoundEffect, _SoundSpec> _specs = {
    // TODO(audio): add assets/audio/ui/run_start_tick.wav
    SoundEffect.run_start_tick: _SoundSpec(
      assetPath: 'assets/audio/ui/run_start_tick.wav',
      fallbackPattern: <({Duration delay, SystemSoundType sound})>[
        (delay: Duration.zero, sound: SystemSoundType.click),
      ],
      cooldown: Duration(milliseconds: 90),
    ),
    // TODO(audio): add assets/audio/ui/correct_ping.wav
    SoundEffect.correct_ping: _SoundSpec(
      assetPath: 'assets/audio/ui/correct_ping.wav',
      cooldown: Duration(milliseconds: 140),
    ),
    // TODO(audio): add assets/audio/ui/combo_burst.wav
    SoundEffect.combo_burst: _SoundSpec(
      assetPath: 'assets/audio/ui/combo_burst.wav',
      cooldown: Duration(milliseconds: 480),
    ),
    // TODO(audio): add assets/audio/rewards/chest_drop.wav
    SoundEffect.chest_drop: _SoundSpec(
      assetPath: 'assets/audio/rewards/chest_drop.wav',
      cooldown: Duration(milliseconds: 300),
    ),
    // TODO(audio): add assets/audio/rewards/chest_open_big.wav
    SoundEffect.chest_open_big: _SoundSpec(
      assetPath: 'assets/audio/rewards/chest_open_big.wav',
      cooldown: Duration(milliseconds: 700),
      haptic: SoundHaptic.mediumImpact,
    ),
    // TODO(audio): add assets/audio/rewards/coin_collect.wav
    SoundEffect.coin_collect: _SoundSpec(
      assetPath: 'assets/audio/rewards/coin_collect.wav',
      cooldown: Duration(milliseconds: 120),
    ),
    // TODO(audio): add assets/audio/rewards/xp_collect.wav
    SoundEffect.xp_collect: _SoundSpec(
      assetPath: 'assets/audio/rewards/xp_collect.wav',
      cooldown: Duration(milliseconds: 120),
    ),
    // TODO(audio): add assets/audio/rewards/rare_fragment_reveal.wav
    SoundEffect.rare_fragment_reveal: _SoundSpec(
      assetPath: 'assets/audio/rewards/rare_fragment_reveal.wav',
      cooldown: Duration(milliseconds: 600),
      haptic: SoundHaptic.selection,
    ),
    // TODO(audio): add assets/audio/rewards/reward_claim.wav
    SoundEffect.reward_claim: _SoundSpec(
      assetPath: 'assets/audio/rewards/reward_claim.wav',
      cooldown: Duration(milliseconds: 300),
      haptic: SoundHaptic.lightImpact,
    ),
  };

  final ValueNotifier<bool> _muted = ValueNotifier<bool>(false);
  final Map<SoundEffect, DateTime> _lastPlayedAt = <SoundEffect, DateTime>{};

  bool _hapticsEnabled = true;
  int _patternToken = 0;

  ValueListenable<bool> get mutedListenable => _muted;
  bool get isMuted => _muted.value;

  Map<String, String> get eventAssetMap => <String, String>{
    for (final entry in _specs.entries) entry.key.name: entry.value.assetPath,
  };

  void setMuted(bool muted) {
    if (_muted.value == muted) {
      return;
    }
    _muted.value = muted;
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  void toggleMuted() {
    setMuted(!isMuted);
  }

  Future<void> play(SoundEffect effect) async {
    final spec = _specs[effect];
    if (spec == null || _isThrottled(effect, spec.cooldown)) {
      return;
    }

    final token = ++_patternToken;
    await _playPairedHaptic(spec.haptic);
    if (isMuted || spec.fallbackPattern.isEmpty) {
      return;
    }

    await _playPattern(spec.fallbackPattern, token: token);
  }

  Future<void> playRunStartTick() => play(SoundEffect.run_start_tick);
  Future<void> playCorrectPing() => play(SoundEffect.correct_ping);
  Future<void> playComboBurst() => play(SoundEffect.combo_burst);
  Future<void> playChestDrop() => play(SoundEffect.chest_drop);
  Future<void> playChestOpenBig() => play(SoundEffect.chest_open_big);
  Future<void> playCoinCollect() => play(SoundEffect.coin_collect);
  Future<void> playXpCollect() => play(SoundEffect.xp_collect);
  Future<void> playRareFragmentReveal() => play(SoundEffect.rare_fragment_reveal);
  Future<void> playRewardClaim() => play(SoundEffect.reward_claim);

  bool _isThrottled(SoundEffect effect, Duration cooldown) {
    if (cooldown <= Duration.zero) {
      return false;
    }

    final now = DateTime.now();
    final previous = _lastPlayedAt[effect];
    if (previous != null && now.difference(previous) < cooldown) {
      return true;
    }

    _lastPlayedAt[effect] = now;
    return false;
  }

  Future<void> _playPairedHaptic(SoundHaptic? haptic) async {
    if (!_hapticsEnabled || haptic == null) {
      return;
    }

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
      debugPrint('Haptic playback fallback: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _playOne(SystemSoundType type) async {
    try {
      await SystemSound.play(type);
    } catch (error, stackTrace) {
      debugPrint('Sound playback fallback: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _playPattern(
    List<({Duration delay, SystemSoundType sound})> pattern,
    {required int token}
  ) async {
    var elapsed = Duration.zero;

    for (final step in pattern) {
      if (token != _patternToken || isMuted) {
        return;
      }

      final wait = step.delay - elapsed;
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }

      if (token != _patternToken || isMuted) {
        return;
      }

      elapsed = step.delay;
      await _playOne(step.sound);
    }
  }
}