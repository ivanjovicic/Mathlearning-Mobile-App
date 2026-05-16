import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/widgets/season_xp_badge.dart';
import 'package:mathlearning/features/learning_map/widgets/chest_open_animation.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_fragment_card.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_unlock_celebration.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_chest.dart';
import 'package:mathlearning/models/cosmetic_fragment_progress.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/models/season.dart';
import 'package:mathlearning/models/user_cosmetic.dart';
import 'package:mathlearning/services/cosmetics_service.dart';
import 'package:mathlearning/services/sound_service.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/widgets/animated_count_label.dart';
import 'package:mathlearning/widgets/cosmetic_visuals.dart';
import 'package:mathlearning/widgets/reward_fly_to_target.dart';
import 'package:mathlearning/widgets/target_fragment_reveal.dart';

// ---------------------------------------------------------------------------
// Sheet phases – drive the entire sequence as a simple state machine.
// ---------------------------------------------------------------------------
enum _Phase { chestDrop, xpReveal, coinsReveal, cosmeticReveal, done }

class DailyChestRewardSheet extends StatefulWidget {
  const DailyChestRewardSheet({
    super.key,
    required this.reward,
    required this.onContinue,
    this.xpTargetKey,
    this.coinTargetKey,
    this.targetCardKey,
    this.seasonXpGained,
    this.milestoneReached,
    this.onApplyXp,
    this.onApplyCoins,
    this.onGrantCosmeticFragment,
    this.onGrantCosmeticFragments,
    this.onApplyTargetProgress,
    this.onMarkRewardTransactionStarted,
    this.onApplyPostChestRewards,
    this.onMarkChestPermanentlyOpened,
    this.onEquipNow,
    this.onViewCollection,
    this.fragmentCountForTesting,
    this.startOpen = false,
  });

  final DailyChestReward reward;
  final VoidCallback onContinue;
  final GlobalKey? xpTargetKey;
  final GlobalKey? coinTargetKey;

  /// When provided, a particle fly animation travels from the
  /// [TargetFragmentFoundBanner] to this key after a target fragment is found.
  /// Typically the key on the [TargetCosmeticChaseCard] in the parent screen.
  final GlobalKey? targetCardKey;

  /// Season XP awarded for this run (null if season feature not available).
  final int? seasonXpGained;

  /// If non-null, the user just crossed this milestone's XP threshold.
  final SeasonMilestone? milestoneReached;

  final FutureOr<void> Function(int amount)? onApplyXp;
  final FutureOr<void> Function(int amount)? onApplyCoins;
  final Future<DailyRunCosmeticGrantResult> Function(String fragmentName)?
  onGrantCosmeticFragment;
  final Future<DailyRunCosmeticGrantResult> Function(
    String fragmentName,
    int copies,
  )?
  onGrantCosmeticFragments;
  final FutureOr<CosmeticTargetProgressEvent?> Function(
    DailyRunCosmeticGrantResult result,
  )?
  onApplyTargetProgress;
  final FutureOr<void> Function()? onMarkRewardTransactionStarted;
  final FutureOr<void> Function()? onApplyPostChestRewards;
  final FutureOr<void> Function()? onMarkChestPermanentlyOpened;
  final FutureOr<void> Function(CosmeticItem item)? onEquipNow;

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

  final GlobalKey _xpSourceKey = GlobalKey(
    debugLabel: 'daily_reward_xp_source',
  );
  final GlobalKey _coinsSourceKey = GlobalKey(
    debugLabel: 'daily_reward_coins_source',
  );
  final GlobalKey _fragmentBannerKey = GlobalKey(
    debugLabel: 'daily_reward_fragment_banner',
  );

  late final CosmeticItem _cosmeticItem;
  late final FragmentRarity _rarity;
  Future<DailyRunCosmeticGrantResult>? _fragmentGrantFuture;
  DailyRunCosmeticGrantResult? _fragmentGrantResult;
  CosmeticTargetProgressEvent? _targetProgressEvent;

  bool _xpApplied = false;
  bool _coinsApplied = false;
  int _impactToken = 0;
  int _screenShakeToken = 0;
  int _chestShakeToken = 0;
  Color? _impactColor;
  // Guard against double-fire (startOpen AND ChestOpenAnimation both calling onOpened).
  bool _rewardSequenceStarted = false;
  bool _isApplyingRewards = false;
  String? _claimErrorMessage;

  @override
  void initState() {
    super.initState();
    _cosmeticItem = CosmeticsService.instance.dailyRunItemForFragment(
      widget.reward.cosmeticFragment,
    );
    _rarity = _rarityFromItem(_cosmeticItem.rarity);
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
    _claimErrorMessage = null;
    unawaited(SoundService.instance.playChestOpenBig());
    setState(() => _phase = _Phase.xpReveal);
    unawaited(_startTransactionalRewardSequence());
  }

  Future<void> _startTransactionalRewardSequence() async {
    if (_isApplyingRewards) return;
    _isApplyingRewards = true;
    try {
      // Keep the reward transaction open until all application callbacks and
      // the backend-backed post-chest refresh have completed.
      await Future.sync(() => widget.onMarkRewardTransactionStarted?.call());
      await _runRewardSequence();
    } catch (error, stackTrace) {
      debugPrint('Daily chest transaction failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.done;
        _claimErrorMessage =
            'Reward claim was interrupted. Retry to safely finish.';
      });
    } finally {
      _isApplyingRewards = false;
    }
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
      sound: SoundEffect.xpCollect,
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
      sound: SoundEffect.coinCollect,
    );

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    final grantFuture = _fragmentGrantFuture ??= _recordFragmentProgress();
    final grantResult = await grantFuture;
    if (!mounted) return;
    final applyTargetProgress = widget.onApplyTargetProgress;
    final CosmeticTargetProgressEvent? targetEvent = applyTargetProgress == null
        ? null
        : await applyTargetProgress(grantResult);
    if (!mounted) return;
    final hasTargetBurst = targetEvent?.targetFragmentFound == true;
    final hasCompletionBurst = grantResult.didUnlock;
    if (hasTargetBurst || hasCompletionBurst) {
      _triggerRewardImpact(
        targetEvent == null
            ? _rarityColor(Theme.of(context).colorScheme)
            : CosmeticVisuals.rarityColor(targetEvent.target.targetRarity),
        isBonus: targetEvent?.bonusFragmentEarned == true,
        isCompletion: hasCompletionBurst,
      );
      if (!_reduceMotion) {
        await Future<void>.delayed(const Duration(milliseconds: 160));
        if (!mounted) return;
      }
    }
    setState(() {
      _fragmentGrantResult = grantResult;
      _targetProgressEvent = targetEvent;
    });
    setState(() => _phase = _Phase.cosmeticReveal);
    unawaited(SoundService.instance.playRareFragmentReveal());
    if (targetEvent?.targetFragmentFound == true) {
      if (targetEvent!.bonusFragmentEarned) {
        // Bonus fragment ceremony: heavier haptic + brief pause so the filled
        // pip row is visible before the banner snaps in.
        unawaited(SoundService.instance.haptic(SoundHaptic.mediumImpact));
        await Future<void>.delayed(const Duration(milliseconds: 220));
        if (!mounted) return;
        unawaited(SoundService.instance.haptic(SoundHaptic.mediumImpact));
      } else {
        unawaited(SoundService.instance.haptic(SoundHaptic.mediumImpact));
      }
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) {
          unawaited(SoundService.instance.playRewardClaim());
        }
      });
      _fireBannerFlyToTarget(targetEvent);
    }

    if (grantResult.didUnlock) {
      // Brief pause so the CosmeticFragmentCard "Unlocked!" state animates in.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _showUnlockCelebration();
      if (!mounted) return;
    } else {
      final hold = targetEvent?.targetFragmentFound == true
          ? const Duration(milliseconds: 1100)
          : const Duration(milliseconds: 650);
      await Future<void>.delayed(_reduceMotion ? Duration.zero : hold);
      if (!mounted) return;
    }

    // Transaction closeout: all reward callbacks succeeded.
    await Future.sync(() => widget.onApplyPostChestRewards?.call());
    await Future.sync(() => widget.onMarkChestPermanentlyOpened?.call());

    setState(() => _phase = _Phase.done);
  }

  void _triggerRewardImpact(
    Color color, {
    required bool isBonus,
    required bool isCompletion,
  }) {
    if (!mounted) return;
    setState(() {
      _impactColor = color;
      _impactToken++;
      _chestShakeToken++;
      if (!_reduceMotion) {
        _screenShakeToken++;
      }
    });

    unawaited(
      SoundService.instance.play(
        isCompletion ? SoundEffect.finalGateUnlocked : SoundEffect.chestOpenBig,
      ),
    );
    if (isBonus || isCompletion) {
      Future<void>.delayed(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        unawaited(SoundService.instance.playRareFragmentReveal());
      });
    }
  }

  Future<DailyRunCosmeticGrantResult> _recordFragmentProgress() async {
    final count = widget.fragmentCountForTesting;
    if (count != null) {
      final collected = count
          .clamp(0, CosmeticsService.dailyRunRequiredFragments)
          .toInt();
      return DailyRunCosmeticGrantResult(
        item: _cosmeticItem,
        progress: CosmeticFragmentProgress(
          itemId: _cosmeticItem.id,
          collectedFragments: collected,
          requiredFragments: CosmeticsService.dailyRunRequiredFragments,
          updatedAt: DateTime.now(),
          unlockedAt: collected >= CosmeticsService.dailyRunRequiredFragments
              ? DateTime.now()
              : null,
        ),
        previousFragments: (collected - 1)
            .clamp(0, CosmeticsService.dailyRunRequiredFragments)
            .toInt(),
        didUnlock: collected >= CosmeticsService.dailyRunRequiredFragments,
      );
    }

    final copies = widget.reward.fragmentCopies.clamp(1, 3).toInt();
    final grantMany = widget.onGrantCosmeticFragments;
    if (grantMany != null) {
      return grantMany(widget.reward.cosmeticFragment, copies);
    }

    final grant = widget.onGrantCosmeticFragment;
    DailyRunCosmeticGrantResult? first;
    DailyRunCosmeticGrantResult? latest;
    var didUnlock = false;
    UserCosmetic? unlockedCosmetic;
    for (var i = 0; i < copies; i++) {
      final next = grant != null
          ? await grant(widget.reward.cosmeticFragment)
          : await CosmeticsService.instance.grantDailyRunFragment(
              fragmentName: widget.reward.cosmeticFragment,
            );
      first ??= next;
      latest = next;
      didUnlock = didUnlock || next.didUnlock;
      unlockedCosmetic ??= next.unlockedCosmetic;
    }

    final resolved = latest!;
    return DailyRunCosmeticGrantResult(
      item: resolved.item,
      progress: resolved.progress,
      previousFragments: first?.previousFragments ?? resolved.previousFragments,
      didUnlock: didUnlock,
      unlockedCosmetic: unlockedCosmetic ?? resolved.unlockedCosmetic,
    );
  }

  /// Fires a particle animation from the fragment found banner to the
  /// [TargetCosmeticChaseCard] in the parent screen after a brief delay so
  /// the banner has time to render and animate in (~240 ms scale).
  void _fireBannerFlyToTarget(CosmeticTargetProgressEvent event) {
    final targetKey = widget.targetCardKey;
    if (targetKey == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final color = CosmeticVisuals.rarityColor(event.target.targetRarity);
      unawaited(
        RewardFlyToTarget.play(
          context,
          sourceKey: _fragmentBannerKey,
          targetKey: targetKey,
          color: color,
          icon: Icons.gps_fixed_rounded,
          debugLabel: 'target_fragment',
          particleCount: 10,
        ),
      );
    });
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

  void _retryClaim() {
    if (_isApplyingRewards) return;
    setState(() {
      _claimErrorMessage = null;
      if (_phase.index < _Phase.xpReveal.index) {
        _phase = _Phase.xpReveal;
      }
    });
    unawaited(_startTransactionalRewardSequence());
  }

  Future<void> _showUnlockCelebration() {
    final itemName = _cosmeticItem.name;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      useRootNavigator: true,
      builder: (dialogContext) => CosmeticUnlockCelebration(
        itemName: itemName,
        rarity: _rarity,
        onEquipNow: () {
          if (widget.onEquipNow == null) return;
          unawaited(Future.sync(() => widget.onEquipNow?.call(_cosmeticItem)));
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
    final hasClaimError = _claimErrorMessage != null;
    final fragmentProgress = _fragmentGrantResult?.progress;
    final targetEvent = _targetProgressEvent;
    final targetFragmentFound = targetEvent?.targetFragmentFound == true;
    final fragmentCollected = fragmentProgress?.collectedFragments ?? 0;
    final fragmentRequired =
        fragmentProgress?.requiredFragments ??
        CosmeticsService.dailyRunRequiredFragments;

    return SafeArea(
      top: false,
      child: _ScreenShake(
        token: _screenShakeToken,
        enabled: !_reduceMotion,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (_impactToken > 0)
              Positioned.fill(
                child: _RewardImpactOverlay(
                  key: ValueKey('reward_impact_overlay_$_impactToken'),
                  color: _impactColor ?? rarityAccent ?? colors.primary,
                  token: _impactToken,
                  intense: targetFragmentFound || _isFragmentComplete,
                  reduceMotion: _reduceMotion,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run cleared!',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleCopy,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (widget.reward.modifierLabels.isNotEmpty ||
                      widget.reward.chestQualityLabel != null) ...[
                    const SizedBox(height: 10),
                    _RewardModifierStrip(reward: widget.reward),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: _ChestImpactShake(
                      token: _chestShakeToken,
                      enabled: !_reduceMotion,
                      child: ChestOpenAnimation(
                        size: 160,
                        accentColor: rarityAccent,
                        isJackpot: isJackpot,
                        onOpened: _onChestOpened,
                      ),
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
                            )
                            .animate()
                            .fadeIn(duration: 180.ms)
                            .slideY(begin: 0.14),
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
                            )
                            .animate()
                            .fadeIn(duration: 180.ms)
                            .slideY(begin: 0.14),
                      ],
                      if (coinsVisible && widget.seasonXpGained != null) ...[
                        const SizedBox(height: 8),
                        SeasonXpBadge(
                          xpGained: widget.seasonXpGained!,
                          milestoneReached: widget.milestoneReached,
                        ),
                      ],
                      if (cosmeticVisible) ...[
                        const SizedBox(height: 8),
                        if (targetFragmentFound && targetEvent != null) ...[
                          TargetFragmentFoundBanner(
                            key: _fragmentBannerKey,
                            event: targetEvent,
                          ),
                          const SizedBox(height: 8),
                        ] else if (targetEvent != null) ...[
                          // Always show bonus progress after every non-target run so
                          // no run ends without visible chase feedback.
                          BonusProgressRow(event: targetEvent),
                          const SizedBox(height: 8),
                        ],
                        CosmeticFragmentCard(
                          fragmentName: _cosmeticItem.name,
                          collected: fragmentCollected,
                          total: fragmentRequired,
                          rarity: _rarity,
                          heading: _fragmentCardHeading,
                          onEquipNow: widget.onEquipNow == null
                              ? null
                              : () {
                                  unawaited(
                                    Future.sync(
                                      () => widget.onEquipNow?.call(
                                        _cosmeticItem,
                                      ),
                                    ),
                                  );
                                },
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
                        DailyChest(
                          state: DailyChestState.locked,
                          onTap: null,
                          size: 42,
                        ),
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
                  if (sequenceDone && (targetEvent?.didComplete ?? false))
                    _NextChaseCta(onContinue: widget.onContinue),
                  if (hasClaimError) ...[
                    const SizedBox(height: 6),
                    Text(
                      _claimErrorMessage!,
                      key: const Key('daily_chest_claim_error'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _ClaimButton(
                    enabled: sequenceDone || hasClaimError,
                    label: hasClaimError
                        ? 'Retry claim'
                        : (targetEvent?.didComplete ?? false)
                        ? 'Continue'
                        : _isFragmentComplete
                        ? 'Done!'
                        : 'Grab it!',
                    onPressed: hasClaimError ? _retryClaim : _handleClaim,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitleCopy {
    final targetEvent = _targetProgressEvent;
    if (targetEvent?.targetFragmentFound == true) {
      if (targetEvent!.didComplete) {
        return '${targetEvent.itemName} is ready to unlock.';
      }
      final gained = targetEvent.fragmentsGained.clamp(1, 999);
      return 'You are now $gained fragment closer to ${targetEvent.itemName}.';
    }
    return switch (_rarity) {
      FragmentRarity.common => 'Nice find!',
      FragmentRarity.rare => 'Big find!',
      FragmentRarity.epic => 'Almost unlocked!',
      FragmentRarity.legendary => 'Legendary find!',
    };
  }

  String get _tomorrowTeaser {
    // When ≥60% of the set is collected, name the item to create a comeback hook.
    final progress = _fragmentGrantResult?.progress;
    if (progress != null &&
        !progress.isUnlocked &&
        progress.collectedFragments * 100 ~/ progress.requiredFragments >= 60) {
      return 'Tomorrow: chance to finish ${_cosmeticItem.name}';
    }
    return switch (_rarity) {
      FragmentRarity.common => 'Tomorrow: +200 XP chest',
      FragmentRarity.rare => 'Tomorrow: Rare fragment chance',
      FragmentRarity.epic => 'Tomorrow: Epic drop incoming',
      FragmentRarity.legendary => 'Tomorrow: Legendary chest chance',
    };
  }

  bool get _isFragmentComplete =>
      _fragmentGrantResult?.progress.isUnlocked ?? false;

  String get _fragmentCardHeading =>
      _targetProgressEvent?.targetFragmentFound == true
      ? 'TARGET FRAGMENT FOUND!'
      : _isFragmentComplete
      ? '${_cosmeticItem.name.toUpperCase()} UNLOCKED!'
      : switch (_rarity) {
          FragmentRarity.common => 'Fragment found!',
          FragmentRarity.rare => 'Rare fragment!',
          FragmentRarity.epic => 'Epic find!',
          FragmentRarity.legendary => 'Legendary find!',
        };

  // ignore: unused_element
  String get _rarityHeading => _targetProgressEvent?.targetFragmentFound == true
      ? 'TARGET FRAGMENT FOUND!'
      : _isFragmentComplete
      ? 'Item unlocked! 🎉'
      : switch (_rarity) {
          FragmentRarity.common => 'Fragment found!',
          FragmentRarity.rare => 'Rare fragment!',
          FragmentRarity.epic => 'Epic find!',
          FragmentRarity.legendary => 'Legendary drop!',
        };

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Color _rarityColor(ColorScheme colors) {
    return switch (_rarity) {
      FragmentRarity.common => colors.secondary,
      FragmentRarity.rare => colors.primary,
      FragmentRarity.epic => colors.tertiary,
      FragmentRarity.legendary => const Color(0xFFFFB800),
    };
  }

  FragmentRarity _rarityFromItem(CosmeticRarity rarity) {
    return switch (rarity) {
      CosmeticRarity.common => FragmentRarity.common,
      CosmeticRarity.rare => FragmentRarity.rare,
      CosmeticRarity.epic || CosmeticRarity.mythic => FragmentRarity.epic,
      CosmeticRarity.legendary => FragmentRarity.legendary,
    };
  }
}

class _ScreenShake extends StatefulWidget {
  const _ScreenShake({
    required this.token,
    required this.enabled,
    required this.child,
  });

  final int token;
  final bool enabled;
  final Widget child;

  @override
  State<_ScreenShake> createState() => _ScreenShakeState();
}

class _ScreenShakeState extends State<_ScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void didUpdateWidget(covariant _ScreenShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && widget.token != oldWidget.token) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      key: const Key('reward_screen_shake'),
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        final amplitude = (1 - t) * 5.0;
        final offset = math.sin(t * math.pi * 8) * amplitude;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class _ChestImpactShake extends StatefulWidget {
  const _ChestImpactShake({
    required this.token,
    required this.enabled,
    required this.child,
  });

  final int token;
  final bool enabled;
  final Widget child;

  @override
  State<_ChestImpactShake> createState() => _ChestImpactShakeState();
}

class _ChestImpactShakeState extends State<_ChestImpactShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void didUpdateWidget(covariant _ChestImpactShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && widget.token != oldWidget.token) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      key: const Key('reward_chest_shake'),
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final shake = math.sin(t * math.pi * 14) * (1 - t) * 9;
        final scale = 1 + math.sin(t * math.pi) * 0.05;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _RewardImpactOverlay extends StatefulWidget {
  const _RewardImpactOverlay({
    super.key,
    required this.color,
    required this.token,
    required this.intense,
    required this.reduceMotion,
  });

  final Color color;
  final int token;
  final bool intense;
  final bool reduceMotion;

  @override
  State<_RewardImpactOverlay> createState() => _RewardImpactOverlayState();
}

class _RewardImpactOverlayState extends State<_RewardImpactOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 980),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _RewardImpactOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.reduceMotion && widget.token != oldWidget.token) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return DecoratedBox(
        key: const Key('reward_fullscreen_flash'),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final flashAlpha = (1 - t).clamp(0.0, 1.0) * 0.30;
        final bloomAlpha = math.sin(t * math.pi).clamp(0.0, 1.0) * 0.24;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  key: const Key('reward_fullscreen_flash'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: widget.color.withValues(alpha: flashAlpha),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: bloomAlpha),
                        blurRadius: 42,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  key: const Key('rarity_particle_explosion'),
                  painter: _RewardExplosionPainter(
                    color: widget.color,
                    t: t,
                    intense: widget.intense,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardExplosionPainter extends CustomPainter {
  const _RewardExplosionPainter({
    required this.color,
    required this.t,
    required this.intense,
  });

  final Color color;
  final double t;
  final bool intense;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final particleCount = intense ? 34 : 22;
    final maxRadius = size.shortestSide * (intense ? 0.58 : 0.42);
    final paint = Paint();

    for (var i = 0; i < particleCount; i++) {
      final angle = (math.pi * 2 / particleCount) * i + (i.isEven ? 0.14 : 0);
      final stagger = (i % 5) * 0.025;
      final progress = ((t - stagger) / (1 - stagger)).clamp(0.0, 1.0);
      if (progress <= 0) continue;
      final eased = Curves.easeOutCubic.transform(progress);
      final radius = maxRadius * eased * (0.62 + (i % 4) * 0.12);
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final alpha = (1 - progress).clamp(0.0, 1.0) * (intense ? 0.95 : 0.65);
      final particleSize = (intense ? 5.2 : 3.8) + (i % 3) * 1.2;
      paint.color = (i % 4 == 0 ? Colors.white : color).withValues(
        alpha: alpha,
      );
      canvas.drawCircle(position, particleSize, paint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = intense ? 5 : 3
      ..color = color.withValues(alpha: (1 - t).clamp(0.0, 1.0) * 0.55);
    canvas.drawCircle(
      center,
      maxRadius * Curves.easeOut.transform(t),
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(_RewardExplosionPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.color != color ||
        oldDelegate.intense != intense;
  }
}

class _RewardModifierStrip extends StatelessWidget {
  const _RewardModifierStrip({required this.reward});

  final DailyChestReward reward;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final labels = <String>[
      if (reward.chestQualityLabel != null) reward.chestQualityLabel!,
      ...reward.modifierLabels,
      if (reward.fragmentCopies > 1) 'x${reward.fragmentCopies} fragments',
    ];
    final visible = labels.take(3).toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in visible)
          Container(
            key: label == 'Welcome-back chest'
                ? const Key('welcome_back_chest_chip')
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
            ),
            child: Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
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

/// Shown in the done phase when a target is completed.
/// Prompts the user to keep the loop alive by picking their next chase.
class _NextChaseCta extends StatelessWidget {
  const _NextChaseCta({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
          key: const Key('next_chase_cta'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.primary.withValues(alpha: 0.38)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Target complete!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "What's next? Pick your next chase to keep the streak alive.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('pick_next_chase_button'),
                  onPressed: onContinue,
                  icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                  label: const Text('Choose your next chase'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 260.ms)
        .slideY(begin: 0.12, curve: Curves.easeOutBack);
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
          .shimmer(duration: 260.ms, color: Colors.white.withValues(alpha: 0.8))
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
