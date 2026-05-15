import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/leaderboard_models.dart';
import '../state/leaderboard_provider.dart';
import '../widgets/leaderboard_tabs.dart';
import '../widgets/period_selector.dart';
import '../widgets/social_cosmetic_avatar.dart';

class SchoolLeaderboardScreen extends StatefulWidget {
  const SchoolLeaderboardScreen({super.key});

  @override
  State<SchoolLeaderboardScreen> createState() =>
      _SchoolLeaderboardScreenState();
}

class _SchoolLeaderboardScreenState extends State<SchoolLeaderboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) {
        return;
      }
      await context.read<LeaderboardProvider>().ensureSchoolsLoaded();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels > threshold) {
      context.read<LeaderboardProvider>().loadMoreSchools();
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = context.select<LeaderboardProvider, LeaderboardPeriod>(
      (value) => value.currentPeriod,
    );
    final items = context
        .select<LeaderboardProvider, List<SchoolLeaderboardEntry>>(
          (value) => value.schoolItems,
        );
    final currentSchool = context
        .select<LeaderboardProvider, SchoolLeaderboardEntry?>(
          (value) => value.currentSchoolEntry,
        );
    final isLoading = context.select<LeaderboardProvider, bool>(
      (value) => value.isLoadingSchools,
    );
    final error = context.select<LeaderboardProvider, Object?>(
      (value) => value.schoolError,
    );
    final isLoadingMore = context.select<LeaderboardProvider, bool>(
      (value) => value.schoolPaging.isLoading && value.schoolItems.isNotEmpty,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('School vs School'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: <Widget>[
                const LeaderboardTabs(
                  selected: LeaderboardTabDestination.schools,
                ),
                const SizedBox(height: 12),
                PeriodSelector(
                  value: period,
                  onChanged: (newPeriod) {
                    context.read<LeaderboardProvider>().changePeriod(
                      newPeriod,
                      board: LeaderboardBoard.schools,
                    );
                  },
                ),
              ],
            ),
          ),
          if (currentSchool != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SchoolSummaryCard(entry: currentSchool),
            ),
          Expanded(
            child: isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : error != null && items.isEmpty
                ? _SchoolLeaderboardError(
                    onRetry: () => context
                        .read<LeaderboardProvider>()
                        .reloadSchoolLeaderboard(),
                  )
                : items.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => context
                        .read<LeaderboardProvider>()
                        .reloadSchoolLeaderboard(),
                    child: ListView(
                      children: const <Widget>[
                        SizedBox(height: 120),
                        Center(child: Text('No schools ranked yet.')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => context
                        .read<LeaderboardProvider>()
                        .reloadSchoolLeaderboard(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: items.length + (isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _SchoolLeaderboardCard(entry: items[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SchoolSummaryCard extends StatelessWidget {
  const _SchoolSummaryCard({required this.entry});

  final SchoolLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.88),
      child: ListTile(
        leading: _SchoolBadge(entry: entry),
        title: Text(
          'Your school: ${entry.schoolName}',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('Rank #${entry.rank} • ${entry.totalScore} total score'),
      ),
    );
  }
}

class _SchoolLeaderboardCard extends StatelessWidget {
  const _SchoolLeaderboardCard({required this.entry});

  final SchoolLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label:
          'School rank ${entry.rank}, ${entry.schoolName}, total score ${entry.totalScore}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.secondaryContainer,
                child: Text(
                  '${entry.rank}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _SchoolBadge(entry: entry),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.schoolName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.members} members',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (entry.badgeLabel != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          entry.badgeLabel!,
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _TopSchoolAvatars(entry: entry),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${entry.totalScore}',
                style: textTheme.titleLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSchoolAvatars extends StatelessWidget {
  const _TopSchoolAvatars({required this.entry});

  final SchoolLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    // Only show avatars the API actually provided. Empty list = honest fallback.
    final avatars = entry.topAvatars;
    if (avatars.isEmpty) {
      return Text(
        'No avatar flex yet',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      height: 34,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < avatars.take(3).length; i++)
            Positioned(
              left: i * 24,
              child: SocialCosmeticAvatar(
                userId: '${entry.schoolId}-$i',
                displayName: '${entry.schoolName} top player ${i + 1}',
                loadout: avatars[i],
                size: 34,
                showRecentBadge: i == 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _SchoolBadge extends StatelessWidget {
  const _SchoolBadge({required this.entry});

  final SchoolLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 18,
      backgroundColor: colors.tertiaryContainer,
      backgroundImage: entry.badgeUrl == null
          ? null
          : NetworkImage(entry.badgeUrl!),
      child: entry.badgeUrl == null
          ? Text(
              entry.schoolName.isEmpty
                  ? '?'
                  : entry.schoolName[0].toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onTertiaryContainer,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _SchoolLeaderboardError extends StatelessWidget {
  const _SchoolLeaderboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('Unable to load the school leaderboard.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
