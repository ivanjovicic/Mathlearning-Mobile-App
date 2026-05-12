import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import '../models/school_leaderboard_models.dart' show SchoolAggregateItem;
import '../models/social_cosmetic_loadout.dart';
import '../theme/app_scale.dart';
import '../theme/theme_extensions/theme_context.dart';
import '../theme/tokens/app_motion.dart';
import 'social_cosmetic_avatar.dart';
import 'ui/app_badge.dart';
import 'ui/app_card.dart';

class LeaderboardItemWidget extends StatelessWidget {
  const LeaderboardItemWidget({
    super.key,
    required this.item,
    this.isCurrentUser = false,
  });

  final LeaderboardItem item;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final leaderboard = context.leaderboardTheme;
    final isTopThree = item.rank <= 3;

    return AppCard(
      margin: EdgeInsets.symmetric(vertical: spacing.xs + spacing.xs / 2),
      padding: EdgeInsets.all(spacing.m),
      backgroundColor: isCurrentUser
          ? leaderboard.currentUserHighlight
          : colors.cardBackground,
      borderColor: isTopThree ? _rankColor(context, item.rank) : colors.border,
      child: Row(
        children: [
          _buildRankBadge(context, item.rank),
          SizedBox(width: spacing.m),
          _buildAvatar(context, item),
          SizedBox(width: spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  'Streak: ${item.streakDays} days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.score} XP',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (isCurrentUser)
                Padding(
                  padding: EdgeInsets.only(top: spacing.xs),
                  child: AppBadge(
                    label: 'You',
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(BuildContext context, int rank) {
    final color = _rankColor(context, rank);
    return CircleAvatar(
      radius: AppScale.s(20),
      backgroundColor: color.withValues(alpha: 0.18),
      child: rank <= 3
          ? Icon(
              Icons.emoji_events,
              color: color,
              size: AppScale.icon(20, min: 18, max: 28),
            )
          : Text(
              '$rank',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }

  Widget _buildAvatar(BuildContext context, LeaderboardItem item) {
    // Use only real API-provided loadout. Empty loadout = honest default.
    final loadout = item.cosmeticLoadout ?? const SocialCosmeticLoadout();
    return SocialCosmeticAvatar(
      userId: item.userId.toString(),
      displayName: item.displayName,
      avatarUrl: item.avatarUrl,
      loadout: loadout,
      size: AppScale.s(44),
    );
  }

  Color _rankColor(BuildContext context, int rank) {
    final leaderboard = context.leaderboardTheme;
    switch (rank) {
      case 1:
        return leaderboard.gold;
      case 2:
        return leaderboard.silver;
      case 3:
        return leaderboard.bronze;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _SchoolTile extends StatelessWidget {
  const _SchoolTile({required this.item});

  final SchoolAggregateItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = context.colors;
    final spacing = context.spacing;
    final rankDelta = item.rankDelta;
    final rankDeltaText = rankDelta == null || rankDelta == 0
        ? null
        : rankDelta > 0
        ? '+$rankDelta'
        : '$rankDelta';

    return Semantics(
      label:
          'School rank ${item.rank}, ${item.schoolName}, score ${item.score}',
      child: AppCard(
        margin: EdgeInsets.symmetric(vertical: spacing.xs + spacing.xs / 2),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: AppScale.s(20),
            backgroundColor: cs.secondaryContainer,
            child: Text('${item.rank}'),
          ),
          title: Text(item.schoolName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item.members} members'),
              if (item.averageXp != null || item.activeStudents != null)
                Text(
                  [
                    if (item.averageXp != null)
                      '${item.averageXp!.toStringAsFixed(1)} avg XP',
                    if (item.activeStudents != null)
                      '${item.activeStudents} active',
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.score}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (rankDeltaText != null)
                Text(
                  rankDeltaText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: rankDelta! > 0 ? context.status.success : cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (item.leagueTier != null && item.leagueTier!.isNotEmpty)
                Text(
                  item.leagueTier!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SchoolLeaderboardTile extends StatelessWidget {
  const SchoolLeaderboardTile({super.key, required this.item});

  final SchoolAggregateItem item;

  @override
  Widget build(BuildContext context) {
    return _SchoolTile(item: item);
  }
}

class AnimatedLeaderboardItem extends StatefulWidget {
  const AnimatedLeaderboardItem({
    super.key,
    required this.item,
    required this.isCurrentUser,
    required this.previousRank,
  });

  final LeaderboardItem item;
  final bool isCurrentUser;
  final int previousRank;

  @override
  State<AnimatedLeaderboardItem> createState() =>
      _AnimatedLeaderboardItemState();
}

class _AnimatedLeaderboardItemState extends State<AnimatedLeaderboardItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppMotion.slow, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).chain(CurveTween(curve: AppMotion.decelerate)).animate(_controller);

    if (widget.item.rank < widget.previousRank) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: LeaderboardItemWidget(
        item: widget.item,
        isCurrentUser: widget.isCurrentUser,
      ),
    );
  }
}
