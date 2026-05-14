import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/models/season.dart';

/// Compact inline banner shown inside the Daily Chest reward sheet after XP is
/// applied, indicating how much season XP was earned and whether a milestone
/// was just reached.
///
/// Designed to be embedded between the coins reveal and the cosmetic reveal
/// so the flow reads: "regular XP → coins → season XP → cosmetic fragment."
class SeasonXpBadge extends StatelessWidget {
  const SeasonXpBadge({
    super.key,
    required this.xpGained,
    this.milestoneReached,
  });

  final int xpGained;

  /// If non-null, a milestone was just crossed by this run's XP award.
  final SeasonMilestone? milestoneReached;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasMilestone = milestoneReached != null;

    return Container(
      key: const Key('season_xp_badge'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasMilestone
            ? colors.primaryContainer
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasMilestone
              ? colors.primary.withValues(alpha: 0.6)
              : colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasMilestone ? Icons.emoji_events_rounded : Icons.auto_awesome,
            size: 20,
            color: hasMilestone ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasMilestone
                      ? 'Milestone reached!'
                      : '+$xpGained Season XP',
                  key: const Key('season_xp_badge_headline'),
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: hasMilestone
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
                if (hasMilestone)
                  Text(
                    '${milestoneReached!.rewardLabel ?? milestoneReached!.label} is ready to claim!',
                    key: const Key('season_milestone_reached_label'),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  )
                else
                  Text(
                    'Building toward season rewards',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 280))
        .slideY(begin: 0.15, end: 0);
  }
}
