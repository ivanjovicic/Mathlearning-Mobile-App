import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/progress_provider.dart';
import 'streak_indicator.dart';

/// Sticky header for the Learning Path screen.
///
/// Shows the user's current streak, level, XP to next level, and a
/// "Today's goal" progress indicator.
class PathHeader extends StatelessWidget implements PreferredSizeWidget {
  const PathHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // XP fill fraction for the current level
    final xpFraction = progress.xpToNextLevel > 0
        ? (progress.xp / progress.xpToNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- Streak ---
          StreakIndicator(streak: progress.streak),
          const SizedBox(width: 12),

          // --- Level + XP bar (expands) ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Level ${progress.level}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${progress.xp} / ${progress.xpToNextLevel} XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: xpFraction,
                    minHeight: 6,
                    backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // --- Accuracy / Today label ---
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${progress.accuracy.toStringAsFixed(0)}%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              Text(
                'accuracy',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
