import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/widgets/chest_open_animation.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_fragment_card.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_unlock_celebration.dart';
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
    this.onViewCollection,
    this.fragmentCountForTesting,
    this.startOpen = false,
  });

  final DailyChestReward reward;
  final VoidCallback onContinue;
  final GlobalKey? xpTargetKey;
  final GlobalKey? coinTargetKey;
  final FutureOr<void> Function(int amount)? onApplyXp;
  final FutureOr<void> Function(int amount)? onApplyCoins;

  /// Called when the user taps "View collection" after unlocking an item.
  final VoidCallback? onViewCollection;

  /// Override the fragment collected count. For testing only.
  /// When null, the count is derived from the fragment name hash.
  final int? fragmentCountForTesting;

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

  late final FragmentRarity _rarity;
  late final int _fragmentCollected;
  late final bool _isFragmentComplete;

  bool _xpApplied = false;
  bool _coinsApplied = false;
  // Guard against double-fire (startOpen AND ChestOpenAnimation both calling onOpened).
  bool _rewardSequenceStarted = false;

  @override
  void initState() {
    super.initState();
    _rarity = _rarityFromFragment(widget.reward.cosmeticFragment);
    _fragmentCollected = widget.fragmentCountForTesting
        ?? _fragmentProgress(widget.reward.cosmeticFragment);
    _isFragmentComplete = _fragmentCollected >= 5;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.startOpen) {
        // In test / skip-animation mode fire chest_drop immediately since
        // there is no visual landing to synchronise with.
        unawaited(SoundService.instance.playChestDrop());
        _onChestOpened();
      } else {
        // Fire chest_drop ~300 ms after mount so it aligns with the visual
        // chest landing (160 ms mount delay + 220 ms shake = ~380 ms total
        // to peak; 300 ms offset lands just before the shake peak).
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          unawaited(SoundService.instance.playChestDrop());
        });
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

    if (_isFragmentComplete) {
      // Brief pause so the CosmeticFragmentCard "Unlocked!" state animates in.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _showUnlockCelebration();
      if (!mounted) return;
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
    }
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

  void _handleClaim() {
    if (!mounted) return;
    unawaited(SoundService.instance.playRewardClaim());
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) widget.onContinue();
    });
  }

  Future<void> _showUnlockCelebration() {
    final itemName = _extractCosmeticName(widget.reward.cosmeticFragment);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      useRootNavigator: true,
      builder: (dialogContext) => CosmeticUnlockCelebration(
        itemName: itemName,
        rarity: _rarity,
        onEquipNow: () {
          Navigator.of(dialogContext).pop();
          widget.onViewCollection?.call();
        },
        onViewCollection: () {
          Navigator.of(dialogContext).pop();
          widget.onViewCollection?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final phase = _phase;

    final bool isJackpot = _rarity != FragmentRarity.common;
    final Color? rarityAccent = switch (_rarity) {
      FragmentRarity.common => null,
      FragmentRarity.rare => colors.primary,
      FragmentRarity.epic => colors.tertiary,
      FragmentRarity.legendary => const Color(0xFFFFB800),
    };

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
              _subtitleCopy,
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Center(
              child: ChestOpenAnimation(
                size: 160,
                accentColor: rarityAccent,
                isJackpot: isJackpot,
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
                    collected: _fragmentCollected,
                    total: 5,
                    rarity: _rarity,
                    heading: _rarityHeading,
                    onEquipNow: widget.onViewCollection,
                    onViewCollection: widget.onViewCollection,
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
                          _tomorrowTeaser,
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
              label: _isFragmentComplete ? 'Done!' : 'Grab it!',
              onPressed: _handleClaim,
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitleCopy => switch (_rarity) {
    FragmentRarity.common => 'Nice find!',
    FragmentRarity.rare => 'Big find!',
    FragmentRarity.epic => 'Huge find! \ud83d\udd25',
    FragmentRarity.legendary => 'LEGENDARY! \ud83d\udca5',
  };

  String get _tomorrowTeaser {
    // When ≥60% of the set is collected, name the item to create a comeback hook.
    if (!_isFragmentComplete && _fragmentCollected >= 3) {
      final name = _extractCosmeticName(widget.reward.cosmeticFragment);
      return 'Tomorrow: chance to finish $name';
    }
    return switch (_rarity) {
      FragmentRarity.common => 'Tomorrow: +200 XP chest',
      FragmentRarity.rare => 'Tomorrow: Rare fragment chance',
      FragmentRarity.epic => 'Tomorrow: Epic drop incoming',
      FragmentRarity.legendary => 'Tomorrow: Legendary chest \ud83d\udc51',
    };
  }

  String get _rarityHeading => _isFragmentComplete
      ? 'Item unlocked! 🎉'
      : switch (_rarity) {
          FragmentRarity.common => 'Fragment found!',
          FragmentRarity.rare => 'Rare fragment!',
          FragmentRarity.epic => 'Epic find!',
          FragmentRarity.legendary => 'Legendary drop!',
        };

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

class _ClaimButton extends StatefulWidget {
  const _ClaimButton({
    required this.enabled,
    required this.onPressed,
    this.label = 'Grab it!',
  });

  final bool enabled;
  final VoidCallback onPressed;
  final String label;

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    Widget btn = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: widget.enabled
            ? () {
                setState(() => _tapped = true);
                widget.onPressed();
              }
            : null,
        child: Text(widget.label),
      ),
    );

    if (widget.enabled && !_tapped) {
      btn = btn
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.025, 1.025),
            duration: 700.ms,
            curve: Curves.easeInOut,
          );
    }

    if (_tapped) {
      btn = btn
          .animate()
          .shimmer(
            duration: 260.ms,
            color: Colors.white.withValues(alpha: 0.8),
          )
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.04, 1.04),
            duration: 130.ms,
            curve: Curves.easeOut,
          );
    }

    return btn;
  }
}
