import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/widgets/chest_open_animation.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_fragment_card.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_chest.dart';
import 'package:mathlearning/services/sound_service.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/widgets/animated_count_label.dart';
import 'package:mathlearning/widgets/reward_fly_to_target.dart';

// ---------------------------------------------------------------------------
// Sheet phases – drive the entire sequence as a simple state machine.
// ---------------------------------------------------------------------------
enum _Phase { chestDrop, opening, xpReveal, coinsReveal, cosmeticReveal, done }

class DailyChestRewardSheet extends StatefulWidget {
  const DailyChestRewardSheet({
    super.key,
    required this.reward,
    required this.onContinue,
    this.xpTargetKey,
    this.coinTargetKey,
    this.onApplyXp,
    this.onApplyCoins,
    this.startOpen = false,
  });

  final DailyChestReward reward;
  final VoidCallback onContinue;
  final GlobalKey? xpTargetKey;
  final GlobalKey? coinTargetKey;
  final FutureOr<void> Function(int amount)? onApplyXp;
  final FutureOr<void> Function(int amount)? onApplyCoins;

  /// Skip the chest open animation and start the reward sequence immediately.
  /// Intended for tests only.
  final bool startOpen;

  @override
  State<DailyChestRewardSheet> createState() => _DailyChestRewardSheetState();
}

class _DailyChestRewardSheetState extends State<DailyChestRewardSheet> {
  _Phase _phase = _Phase.chestDrop;

  final GlobalKey _xpSourceKey = GlobalKey(debugLabel: 'daily_reward_xp_source');
  final GlobalKey _coinsSourceKey = GlobalKey(debugLabel: 'daily_reward_coins_source');

  bool _xpApplied = false;
  bool _coinsApplied = false;
  // Guard against double-fire (startOpen AND ChestOpenAnimation both calling onOpened).
  bool _rewardSequenceStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(SoundService.instance.playChestDrop());
      if (widget.startOpen) {
        _onChestOpened();
      }
    });
  }

  void _onChestOpened() {
    if (!mounted || _rewardSequenceStarted) return;
    _rewardSequenceStarted = true;
    unawaited(SoundService.instance.playChestOpenBig());
    setState(() => _phase = _Phase.xpReveal);
    unawaited(_runRewardSequence());
  }

  Future<void> _runRewardSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) return;
    await _flyAndApply(
      sourceKey: _xpSourceKey,
      targetKey: widget.xpTargetKey,
      color: Theme.of(context).colorScheme.primary,
      icon: Icons.bolt_rounded,
      debugLabel: 'xp',
      isApplied: () => _xpApplied,
      markApplied: () => _xpApplied = true,
      onApply: () => widget.onApplyXp?.call(widget.reward.xp),
      sound: SoundEffect.xp_collect,
    );

    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    setState(() => _phase = _Phase.coinsReveal);

    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) return;
    await _flyAndApply(
      sourceKey: _coinsSourceKey,
      targetKey: widget.coinTargetKey,
      color: Theme.of(context).colorScheme.secondary,
      icon: Icons.monetization_on_rounded,
      debugLabel: 'coins',
      isApplied: () => _coinsApplied,
      markApplied: () => _coinsApplied = true,
      onApply: () => widget.onApplyCoins?.call(widget.reward.coins),
      sound: SoundEffect.coin_collect,
    );

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _phase = _Phase.cosmeticReveal);
    unawaited(SoundService.instance.playRareFragmentReveal());

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
  }

  Future<void> _flyAndApply({
    required GlobalKey sourceKey,
    required GlobalKey? targetKey,
    required Color color,
    required IconData icon,
    required String debugLabel,
    required bool Function() isApplied,
    required VoidCallback markApplied,
    required FutureOr<void> Function()? onApply,
    required SoundEffect sound,
  }) async {
    if (isApplied()) return;

    var played = false;
    if (mounted && targetKey != null) {
      try {
        played = await RewardFlyToTarget.play(
          context,
          sourceKey: sourceKey,
          targetKey: targetKey,
          color: color,
          icon: icon,
          debugLabel: debugLabel,
        );
        if (played) {
          unawaited(SoundService.instance.play(sound));
        }
      } catch (_) {
        played = false;
      }
    }

    if (!played || mounted) {
      markApplied();
      await Future.sync(() => onApply?.call());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final phase = _phase;

    final xpVisible = phase.index >= _Phase.xpReveal.index;
    final coinsVisible = phase.index >= _Phase.coinsReveal.index;
    final cosmeticVisible = phase.index >= _Phase.cosmeticReveal.index;
    final sequenceDone = phase == _Phase.done;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Run cleared!',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Crack the chest and claim your loot',
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Center(
              child: ChestOpenAnimation(
                size: 90,
                onOpened: _onChestOpened,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                if (xpVisible)
                  _RewardRow(
                    rowKey: _xpSourceKey,
                    icon: Icons.bolt_rounded,
                    color: colors.primary,
                    label: AnimatedCountLabel(
                      to: widget.reward.xp,
                      prefix: '+',
                      suffix: ' XP',
                      duration: const Duration(milliseconds: 600),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                  ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.14),
                if (coinsVisible) ...[
                  const SizedBox(height: 8),
                  _RewardRow(
                    rowKey: _coinsSourceKey,
                    icon: Icons.monetization_on_rounded,
                    color: colors.secondary,
                    label: AnimatedCountLabel(
                      to: widget.reward.coins,
                      prefix: '+',
                      suffix: ' coins',
                      duration: const Duration(milliseconds: 600),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.secondary,
                      ),
                    ),
                  ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.14),
                ],
                if (cosmeticVisible) ...[
                  const SizedBox(height: 8),
                  CosmeticFragmentCard(
                    fragmentName: _extractCosmeticName(widget.reward.cosmeticFragment),
                    collected: _fragmentProgress(widget.reward.cosmeticFragment),
                    total: 5,
                    rarity: _rarityFromFragment(widget.reward.cosmeticFragment),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  DailyChest(state: DailyChestState.locked, onTap: null, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tomorrow',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "Tomorrow's chest is even better 👀",
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ClaimButton(
              enabled: sequenceDone,
              onPressed: widget.onContinue,
            ),
          ],
        ),
      ),
    );
  }

  String _extractCosmeticName(String raw) {
    const suffix = ' Fragment';
    if (raw.endsWith(suffix)) {
      return raw.substring(0, raw.length - suffix.length);
    }
    return raw;
  }

  int _fragmentProgress(String raw) {
    var hash = 0;
    for (final c in raw.codeUnits) {
      hash = ((hash * 31) + c) & 0x7fffffff;
    }
    return 1 + (hash % 5);
  }

  FragmentRarity _rarityFromFragment(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('neon') || lower.contains('burst')) return FragmentRarity.epic;
    if (lower.contains('nova') || lower.contains('comet')) return FragmentRarity.rare;
    return FragmentRarity.common;
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    this.rowKey,
    required this.icon,
    required this.color,
    required this.label,
  });

  final Key? rowKey;
  final IconData icon;
  final Color color;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: rowKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          label,
        ],
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    Widget btn = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled
            ? () {
                unawaited(SoundService.instance.playRewardClaim());
                onPressed();
              }
            : null,
        child: const Text('Claim rewards!'),
      ),
    );

    if (enabled) {
      btn = btn
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.025, 1.025),
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    return btn;
  }
}
