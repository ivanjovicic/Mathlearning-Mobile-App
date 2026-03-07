import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import '../models/school_leaderboard_models.dart' show SchoolAggregateItem;

class LeaderboardItemWidget extends StatelessWidget {
  final LeaderboardItem item;
  final bool isCurrentUser;

  const LeaderboardItemWidget({
    super.key,
    required this.item,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isTopThree = item.rank <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? cs.primaryContainer.withValues(alpha: 0.2)
            : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTopThree ? _rankColor(item.rank) : cs.outline,
          width: isTopThree ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildRankBadge(item.rank, cs),
          const SizedBox(width: 12),
          _buildAvatar(item, cs),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Streak: ${item.streakDays} days',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.score} XP',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              if (isCurrentUser)
                Text(
                  'You',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.secondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank, ColorScheme cs) {
    final color = _rankColor(rank);
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: rank <= 3
          ? Icon(
              Icons.emoji_events,
              color: color,
            )
          : Text(
              '$rank',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildAvatar(LeaderboardItem item, ColorScheme cs) {
    return CircleAvatar(
      backgroundImage: item.avatarUrl != null
          ? NetworkImage(item.avatarUrl!)
          : null,
      child: item.avatarUrl == null
          ? Text(
              item.displayName[0].toUpperCase(),
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return const Color(0xFFCD7F32); // Bronze color
      default:
        return Colors.blueGrey;
    }
  }
}

class _SchoolTile extends StatelessWidget {
  final SchoolAggregateItem item;

  const _SchoolTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rankDelta = item.rankDelta;
    final rankDeltaText = rankDelta == null || rankDelta == 0
        ? null
        : rankDelta > 0
        ? '+$rankDelta'
        : '$rankDelta';
    return Semantics(
      label: 'School rank ${item.rank}, ${item.schoolName}, score ${item.score}',
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
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
                style: TextStyle(
                  color: cs.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (rankDeltaText != null)
                Text(
                  rankDeltaText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: rankDelta! > 0 ? Colors.green : cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (item.leagueTier != null && item.leagueTier!.isNotEmpty)
                Text(
                  item.leagueTier!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
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

/// Public tile for displaying school aggregate items in the school leaderboard.
class SchoolLeaderboardTile extends StatelessWidget {
  final SchoolAggregateItem item;

  const SchoolLeaderboardTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return _SchoolTile(item: item);
  }
}

class AnimatedLeaderboardItem extends StatefulWidget {
  final LeaderboardItem item;
  final bool isCurrentUser;
  final int previousRank;

  const AnimatedLeaderboardItem({
    super.key,
    required this.item,
    required this.isCurrentUser,
    required this.previousRank,
  });

  @override
  State<AnimatedLeaderboardItem> createState() => _AnimatedLeaderboardItemState();
}

class _AnimatedLeaderboardItemState extends State<AnimatedLeaderboardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);

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
