import 'package:flutter/material.dart';

import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';
import 'package:mathlearning/widgets/ui/app_card.dart';
import 'package:mathlearning/widgets/animated_xp_bar.dart';

class XpLevelChip extends StatelessWidget {
  const XpLevelChip({
    super.key,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    this.progressBarKey,
  });

  final int level;
  final int xp;
  final int xpToNextLevel;
  final Key? progressBarKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final spacing = context.spacing;
    final remaining = (xpToNextLevel - xp).clamp(0, xpToNextLevel);

    return AppCard(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.m,
        vertical: spacing.s + spacing.xs,
      ),
      backgroundColor: cs.secondaryContainer.withValues(alpha: 0.45),
      borderColor: cs.secondary.withValues(alpha: 0.20),
      child: Row(
        children: [
          Container(
            width: AppScale.s(38),
            height: AppScale.s(38),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.secondary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$level',
              style: tt.titleSmall?.copyWith(
                color: cs.onSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: spacing.s + spacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $level',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$remaining XP to level up!',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing.xs),
                SizedBox(
                  key: progressBarKey,
                  child: AnimatedXpBar(
                    currentXp: xp,
                    maxXp: xpToNextLevel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
