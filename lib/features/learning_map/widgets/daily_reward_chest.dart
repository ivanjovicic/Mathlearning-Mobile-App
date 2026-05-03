import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/models/daily_reward.dart';
import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';
import 'package:mathlearning/widgets/ui/app_card.dart';

enum DailyRewardChestState { locked, ready, opened }

class DailyRewardChest extends StatefulWidget {
  const DailyRewardChest({
    super.key,
    required this.state,
    required this.reward,
    this.onOpen,
  });

  final DailyRewardChestState state;
  final DailyReward reward;
  final Future<void> Function()? onOpen;

  @override
  State<DailyRewardChest> createState() => _DailyRewardChestState();
}

class _DailyRewardChestState extends State<DailyRewardChest> {
  Timer? _burstTimer;
  bool _isClaiming = false;
  bool _playOpenedBurst = false;

  @override
  void didUpdateWidget(covariant DailyRewardChest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != DailyRewardChestState.opened &&
        widget.state == DailyRewardChestState.opened) {
      _burstTimer?.cancel();
      setState(() => _playOpenedBurst = true);
      _burstTimer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => _playOpenedBurst = false);
      });
    }
  }

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.spacing;

    final background = switch (widget.state) {
      DailyRewardChestState.locked => colors.surfaceContainerLow,
      DailyRewardChestState.ready => colors.tertiaryContainer.withValues(alpha: 0.75),
      DailyRewardChestState.opened => colors.primaryContainer.withValues(alpha: 0.55),
    };

    final borderColor = switch (widget.state) {
      DailyRewardChestState.locked => colors.outlineVariant,
      DailyRewardChestState.ready => colors.tertiary,
      DailyRewardChestState.opened => colors.primary,
    };

    final glowColor = switch (widget.state) {
      DailyRewardChestState.locked => colors.outline,
      DailyRewardChestState.ready => colors.tertiary,
      DailyRewardChestState.opened => colors.primary,
    };

    final headline = switch (widget.state) {
      DailyRewardChestState.locked => 'Finish 1 practice round to unlock today\'s chest!',
      DailyRewardChestState.ready => 'Daily reward ready!',
      DailyRewardChestState.opened => 'Come back tomorrow for a new one!',
    };

    final subline = switch (widget.state) {
      DailyRewardChestState.locked => 'Play one round today and your chest will open.',
      DailyRewardChestState.ready => widget.reward.subtitle,
      DailyRewardChestState.opened => 'Nice! You opened today\'s chest.',
    };

    final rewardRow = Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.s + spacing.xs / 2),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(context.radius.medium),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            _rewardIcon(widget.reward.type),
            color: borderColor,
            size: AppScale.icon(18, min: 16, max: 22),
          ),
          SizedBox(width: spacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reward.title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: spacing.xs / 2),
                Text(
                  widget.reward.subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final card = AnimatedContainer(
      duration: context.motion.normal,
      curve: context.motion.decelerate,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.radius.card),
        boxShadow: [
          if (widget.state != DailyRewardChestState.locked)
            BoxShadow(
              color: glowColor.withValues(
                alpha: widget.state == DailyRewardChestState.ready ? 0.22 : 0.14,
              ),
              blurRadius: AppScale.s(18),
              spreadRadius: AppScale.s(1.5),
            ),
        ],
      ),
      child: AppCard(
        backgroundColor: background,
        borderColor: borderColor.withValues(alpha: 0.55),
        padding: EdgeInsets.all(spacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedScale(
                  scale: _playOpenedBurst ? 1.18 : 1.0,
                  duration: context.motion.fast,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    _chestIcon(widget.state),
                    color: borderColor,
                    size: AppScale.icon(30, min: 26, max: 36),
                  ),
                ),
                SizedBox(width: spacing.s + spacing.xs / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: spacing.xs / 2),
                      Text(
                        subline,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.s + spacing.xs / 2),
            AnimatedSwitcher(
              duration: context.motion.normal,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: widget.state == DailyRewardChestState.locked
                  ? const SizedBox.shrink()
                  : rewardRow,
            ),
            if (widget.state == DailyRewardChestState.ready) ...[
              SizedBox(height: spacing.s + spacing.xs / 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isClaiming ? null : _handleOpen,
                  icon: _isClaiming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Open reward'),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.state == DailyRewardChestState.ready) {
      return card
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: 1900.ms,
            color: glowColor.withValues(alpha: 0.10),
          );
    }

    return card;
  }

  Future<void> _handleOpen() async {
    final onOpen = widget.onOpen;
    if (onOpen == null || _isClaiming) {
      return;
    }

    setState(() => _isClaiming = true);
    HapticFeedback.mediumImpact();
    try {
      await onOpen();
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  IconData _chestIcon(DailyRewardChestState state) {
    return switch (state) {
      DailyRewardChestState.locked => Icons.lock_rounded,
      DailyRewardChestState.ready => Icons.redeem_rounded,
      DailyRewardChestState.opened => Icons.inventory_2_rounded,
    };
  }

  IconData _rewardIcon(DailyRewardType type) {
    return switch (type) {
      DailyRewardType.xp => Icons.bolt_rounded,
      DailyRewardType.cosmetic => Icons.palette_rounded,
      DailyRewardType.streakBoost => Icons.local_fire_department_rounded,
    };
  }
}