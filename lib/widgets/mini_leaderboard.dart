import 'package:flutter/material.dart';

import '../models/cosmetic_target.dart';
import '../models/leaderboard_models.dart';
import '../models/social_cosmetic_loadout.dart';
import 'cosmetic_flex_chip.dart';
import 'cosmetic_target_chip.dart';
import 'social_cosmetic_avatar.dart';
import 'weekly_featured_flair_chip.dart';

class MiniLeaderboard extends StatelessWidget {
  const MiniLeaderboard({
    super.key,
    required this.entries,
    required this.currentUserId,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.currentUserLoadout,
    this.currentUserTarget,
    this.weeklyFeaturedCompletionLabel,
  });

  final List<RivalLeaderboardEntry> entries;
  final int? currentUserId;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final SocialCosmeticLoadout? currentUserLoadout;
  final CosmeticTarget? currentUserTarget;
  final String? weeklyFeaturedCompletionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Rivals nearby',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Two above you, two below you.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              _MiniLeaderboardError(message: errorMessage!, onRetry: onRetry)
            else if (entries.isEmpty)
              Text(
                'No rivals available yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            else
              Column(
                children: entries
                    .map(
                      (entry) => _MiniLeaderboardRow(
                        key: ValueKey<String>(
                          'rival-${entry.userId}-${entry.rank}',
                        ),
                        entry: entry,
                        isCurrentUser: entry.userId == currentUserId,
                        currentUserLoadout: currentUserLoadout,
                        currentUserTarget: currentUserTarget,
                        weeklyFeaturedCompletionLabel:
                            weeklyFeaturedCompletionLabel,
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniLeaderboardError extends StatelessWidget {
  const _MiniLeaderboardError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(message)),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _MiniLeaderboardRow extends StatelessWidget {
  const _MiniLeaderboardRow({
    super.key,
    required this.entry,
    required this.isCurrentUser,
    this.currentUserLoadout,
    this.currentUserTarget,
    this.weeklyFeaturedCompletionLabel,
  });

  final RivalLeaderboardEntry entry;
  final bool isCurrentUser;
  final SocialCosmeticLoadout? currentUserLoadout;
  final CosmeticTarget? currentUserTarget;
  final String? weeklyFeaturedCompletionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final loadout =
        isCurrentUser && currentUserLoadout?.hasEquippedCosmetics == true
        ? currentUserLoadout!
        : entry.cosmeticLoadout ?? const SocialCosmeticLoadout();
    final target = isCurrentUser && currentUserTarget != null
        ? currentUserTarget
        : null;
    final weeklyLabel = isCurrentUser ? weeklyFeaturedCompletionLabel : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colors.primaryContainer.withValues(alpha: 0.9)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser
              ? colors.primary.withValues(alpha: 0.45)
              : colors.outlineVariant,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 76,
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '#${entry.rank}',
                      key: ValueKey<int>(entry.rank),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SocialCosmeticAvatar(
                  userId: entry.userId.toString(),
                  displayName: entry.displayName,
                  avatarUrl: entry.avatarUrl,
                  loadout: loadout,
                  size: 38,
                  isCurrentUser: isCurrentUser,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.displayName,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${entry.score} XP',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (loadout.hasEquippedCosmetics)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: CosmeticFlexChip(
                      loadout: loadout,
                      isCurrentUser: isCurrentUser,
                      compact: true,
                      maxWidth: 118,
                    ),
                  ),
                if (target != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: CosmeticTargetChip(
                      target: target,
                      compact: true,
                      maxWidth: 118,
                    ),
                  ),
                if (weeklyLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: WeeklyFeaturedFlairChip(
                      label: weeklyLabel,
                      compact: true,
                      maxWidth: 118,
                    ),
                  ),
              ],
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'You',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
