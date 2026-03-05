import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import '../models/school_leaderboard_models.dart' show SchoolAggregateItem;

class LeaderboardItemWidget extends StatelessWidget {
  final dynamic item;
  final bool isLoading;
  final String? errorMessage;
  final bool isCurrentUser;

  const LeaderboardItemWidget({
    super.key,
    this.item,
    this.isLoading = false,
    this.errorMessage,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LeaderboardLoadingTile();
    if (errorMessage != null) {
      return _LeaderboardErrorTile(message: errorMessage!);
    }
    if (item == null) return const SizedBox.shrink();

    if (item is LeaderboardItem) {
      return _UserTile(item: item as LeaderboardItem, isCurrentUser: isCurrentUser);
    }

    if (item is SchoolAggregateItem) {
      return _SchoolTile(item: item as SchoolAggregateItem);
    }

    return ListTile(
      title: Text(item.toString()),
      dense: true,
    );
  }
}

class _UserTile extends StatelessWidget {
  final LeaderboardItem item;
  final bool isCurrentUser;

  const _UserTile({required this.item, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      label: 'Rank ${item.rank}, ${item.displayName}, ${item.score} points',
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: isCurrentUser ? cs.primaryContainer.withValues(alpha: 0.45) : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.surfaceContainerHighest,
            child: Text('${item.rank}'),
          ),
          title: Text(
            item.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          subtitle: Text('Streak: ${item.streakDays} days'),
          trailing: Text(
            '${item.score}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SchoolTile extends StatelessWidget {
  final SchoolAggregateItem item;

  const _SchoolTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          subtitle: Text('${item.members} members'),
          trailing: Text(
            '${item.score}',
            style: TextStyle(
              color: cs.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardLoadingTile extends StatelessWidget {
  const _LeaderboardLoadingTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: cs.surfaceContainerHighest),
        title: Container(height: 12, color: cs.surfaceContainerHighest),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(height: 10, color: cs.surfaceContainerHigh),
        ),
      ),
    );
  }
}

class _LeaderboardErrorTile extends StatelessWidget {
  final String message;

  const _LeaderboardErrorTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cs.errorContainer.withValues(alpha: 0.55),
      child: ListTile(
        leading: Icon(Icons.error_outline_rounded, color: cs.error),
        title: const Text('Could not load leaderboard row'),
        subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
