import 'package:flutter/material.dart';

import 'package:mathlearning/models/daily_return.dart';

class DailyReturnPanel extends StatelessWidget {
  const DailyReturnPanel({
    super.key,
    required this.state,
    this.compact = false,
    this.margin = EdgeInsets.zero,
  });

  final DailyReturnState state;
  final bool compact;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPressure =
        state.streakAtRisk ||
        state.hasComebackReward ||
        state.modifiers.any(
          (entry) => entry.type == DailyReturnModifierType.finalDayBonus,
        );
    final accent = state.streakAtRisk
        ? colors.error
        : state.hasDoubleFragmentDay
        ? colors.tertiary
        : colors.primary;

    return Container(
      key: const Key('daily_return_panel'),
      margin: margin,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: isPressure
            ? accent.withValues(alpha: 0.12)
            : colors.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FlameBadge(
                streak: state.currentStreak,
                atRisk: state.streakAtRisk,
                color: accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.primaryMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: isPressure ? accent : colors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.supportiveMessage,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ReturnChip(
                label: '${state.streakMultiplier.toStringAsFixed(2)}x',
                tooltip: 'Streak multiplier',
                icon: Icons.local_fire_department_rounded,
                color: accent,
              ),
              _ReturnChip(
                label: state.chestQualityLabel,
                tooltip: 'Chest quality improves with real streak length.',
                icon: Icons.card_giftcard_rounded,
                color: colors.secondary,
              ),
              for (final modifier in state.modifiers.take(compact ? 2 : 3))
                _ReturnChip(
                  label: modifier.shortLabel,
                  tooltip: modifier.description,
                  icon: _iconFor(modifier.type),
                  color: colors.tertiary,
                ),
            ],
          ),
          if (!compact && state.weeklyGoals.isNotEmpty) ...[
            const SizedBox(height: 10),
            _WeeklyGoalRow(goal: state.weeklyGoals.first),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(DailyReturnModifierType type) {
    return switch (type) {
      DailyReturnModifierType.doubleFragmentDay => Icons.diamond_rounded,
      DailyReturnModifierType.bonusXpRun => Icons.bolt_rounded,
      DailyReturnModifierType.streakBonusActive =>
        Icons.local_fire_department_rounded,
      DailyReturnModifierType.featuredCosmeticBoost => Icons.auto_awesome,
      DailyReturnModifierType.finalDayBonus => Icons.hourglass_bottom_rounded,
    };
  }
}

class _FlameBadge extends StatelessWidget {
  const _FlameBadge({
    required this.streak,
    required this.atRisk,
    required this.color,
  });

  final int streak;
  final bool atRisk;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = streak >= 30
        ? 38.0
        : streak >= 14
        ? 34.0
        : streak >= 7
        ? 31.0
        : 28.0;
    return Container(
      key: const Key('daily_return_streak_flame'),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: atRisk ? 0.18 : 0.14),
        border: Border.all(color: color.withValues(alpha: 0.40)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: streak >= 7 ? 0.34 : 0.16),
            blurRadius: streak >= 14 ? 18 : 10,
            spreadRadius: streak >= 30 ? 2 : 0,
          ),
        ],
      ),
      child: Icon(
        atRisk ? Icons.warning_amber_rounded : Icons.local_fire_department,
        color: color,
        size: size,
      ),
    );
  }
}

class _ReturnChip extends StatelessWidget {
  const _ReturnChip({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.color,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyGoalRow extends StatelessWidget {
  const _WeeklyGoalRow({required this.goal});

  final DailyReturnWeeklyGoal goal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.title,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              goal.compactLabel,
              style: textTheme.labelSmall?.copyWith(
                color: goal.isComplete
                    ? colors.primary
                    : colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: goal.progressValue,
            minHeight: 5,
            backgroundColor: colors.outlineVariant.withValues(alpha: 0.35),
            valueColor: AlwaysStoppedAnimation<Color>(
              goal.isComplete ? colors.primary : colors.tertiary,
            ),
          ),
        ),
      ],
    );
  }
}
