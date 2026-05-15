import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/learning_map/widgets/daily_chest.dart';
import 'package:mathlearning/features/learning_map/widgets/season_hub_sheet.dart';
import 'package:mathlearning/models/season.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/daily_return_provider.dart';
import 'package:mathlearning/state/season_provider.dart';
import 'package:mathlearning/widgets/daily_return_panel.dart';
import 'package:mathlearning/widgets/target_cosmetic_chase_card.dart';
import 'package:mathlearning/widgets/weekly_featured_banner.dart';

class DailyRunCard extends StatelessWidget {
  const DailyRunCard({
    super.key,
    required this.isCompleted,
    required this.chestState,
    required this.onStart,
    required this.onOpenChest,
    this.chaseCardKey,
  });

  final bool isCompleted;
  final DailyChestState chestState;
  final VoidCallback onStart;
  final VoidCallback onOpenChest;

  /// Optional GlobalKey passed to the embedded [TargetCosmeticChaseCard].
  /// Used by the reward sheet to fly particles to the chase card.
  final GlobalKey? chaseCardKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final seasonProvider = context.watch<SeasonProvider?>();
    final season = seasonProvider?.season;
    final seasonStatus = season?.status(DateTime.now());
    final returnState = context.watch<DailyReturnProvider?>()?.state;

    final subtitle = switch (chestState) {
      DailyChestState.locked =>
        returnState?.primaryMessage ?? 'Finish it to unlock today\'s reward',
      DailyChestState.ready => 'Daily reward ready!',
      DailyChestState.opened => 'Come back tomorrow for a new one!',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season urgency strip + hub entry
          if (season != null)
            _SeasonStrip(
              season: season,
              status: seasonStatus ?? SeasonStatus.ended,
              earnedXp: seasonProvider?.earnedXp ?? 0,
              totalXp: seasonProvider?.totalXpGoal ?? 500,
              onTap: () => showSeasonHub(context),
            ),
          if (season != null) const SizedBox(height: 10),
          Text(
            'Your Daily Run is ready',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer.withValues(alpha: 0.86),
            ),
          ),
          if (returnState != null)
            DailyReturnPanel(
              state: returnState,
              compact: true,
              margin: const EdgeInsets.only(top: 12),
            ),
          TargetCosmeticChaseCard(
            key: chaseCardKey,
            compact: true,
            margin: const EdgeInsets.only(top: 12),
          ),
          const WeeklyFeaturedBanner(
            compact: true,
            margin: EdgeInsets.only(top: 10),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: _RunStepsRow()),
              const SizedBox(width: 10),
              Column(
                children: [
                  DailyChest(
                    state: chestState,
                    onTap: chestState == DailyChestState.ready
                        ? onOpenChest
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chestState == DailyChestState.ready
                        ? 'Open your chest'
                        : 'Daily Chest',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('daily_run_start_button'),
              onPressed: isCompleted ? null : onStart,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: Text(isCompleted ? 'Run Complete' : 'Start Run →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunStepsRow extends StatelessWidget {
  const _RunStepsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StepPill(label: 'Warm-up', icon: Icons.wb_sunny_outlined),
        _StepDivider(),
        _StepPill(label: 'Challenge', icon: Icons.bolt_rounded),
        _StepDivider(),
        _StepPill(label: 'Final Gate', icon: Icons.flag_rounded),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: colors.onSurface),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: colors.onPrimaryContainer.withValues(alpha: 0.8),
      ),
    );
  }
}

// ── Season strip ──────────────────────────────────────────────────────────

class _SeasonStrip extends StatelessWidget {
  const _SeasonStrip({
    required this.season,
    required this.status,
    required this.earnedXp,
    required this.totalXp,
    required this.onTap,
  });

  final Season season;
  final SeasonStatus status;
  final int earnedXp;
  final int totalXp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fraction = totalXp > 0 ? (earnedXp / totalXp).clamp(0.0, 1.0) : 0.0;
    final isUrgent = status.isUrgent;
    final urgencyText = status.urgencyLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('daily_run_card_season_strip'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUrgent
              ? colors.errorContainer.withValues(alpha: 0.8)
              : colors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isUrgent
                ? colors.error.withValues(alpha: 0.5)
                : colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.military_tech_rounded,
              size: 16,
              color: isUrgent ? colors.error : colors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          urgencyText.isNotEmpty ? urgencyText : season.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isUrgent
                                ? colors.onErrorContainer
                                : colors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '$earnedXp/$totalXp XP',
                        style: textTheme.labelSmall?.copyWith(
                          color: isUrgent
                              ? colors.onErrorContainer
                              : colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 4,
                      backgroundColor: colors.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUrgent ? colors.error : colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
