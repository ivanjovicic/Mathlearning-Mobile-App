import 'package:flutter/material.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:provider/provider.dart';

import '../models/leaderboard_models.dart';
import '../models/social_cosmetic_loadout.dart';
import '../navigation/navigation_extensions.dart';
import '../state/avatar_provider.dart';
import '../state/auth_provider.dart';
import '../state/cosmetic_target_provider.dart';
import '../state/leaderboard_provider.dart';
import '../state/player_identity_provider.dart';
import '../state/weekly_featured_provider.dart';
import '../theme/app_scale.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../widgets/animated_leaderboard_item.dart';
import '../widgets/leaderboard_header.dart';
import '../widgets/leaderboard_search_bar.dart';
import '../widgets/leaderboard_tabs.dart';
import '../widgets/mini_leaderboard.dart';
import '../widgets/period_selector.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, this.autoLoad = true});

  final bool autoLoad;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, int> _previousRanks = <int, int>{};
  String _query = '';
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      if (!mounted) {
        return;
      }
      try {
        final auth = context.read<AuthProvider>();
        context.read<LeaderboardProvider>().setCurrentUserId(
          int.tryParse(auth.userId ?? ''),
        );
      } catch (_) {}
      if (widget.autoLoad) {
        await context.read<LeaderboardProvider>().ensureUsersLoaded();
      }
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
    if (!_scrollController.hasClients || _isLoadingMore) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels <= threshold) {
      return;
    }

    setState(() => _isLoadingMore = true);
    context
        .read<LeaderboardProvider>()
        .loadMore(LeaderboardScope.global)
        .whenComplete(() {
          if (!mounted) {
            return;
          }
          setState(() => _isLoadingMore = false);
        });
  }

  List<LeaderboardItem> _filterItems(List<LeaderboardItem> items) {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return items;
    }

    return items
        .where(
          (item) => item.displayName.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  Future<void> _refreshUsers() {
    final provider = context.read<LeaderboardProvider>();
    return Future.wait<void>(<Future<void>>[
      provider.reloadScope(LeaderboardScope.global),
      provider.fetchRivals(),
    ]);
  }

  Widget _buildShimmerLoading() {
    return Center(
      child: ConstrainedBox(
        constraints: AppScale.centeredContentConstraints(),
        child: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) {
            return const ListTileShimmer(
              isRectBox: true,
              isDisabledAvatar: false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final period = context.select<LeaderboardProvider, LeaderboardPeriod>(
      (value) => value.currentPeriod,
    );
    final items = _filterItems(
      context.select<LeaderboardProvider, List<LeaderboardItem>>(
        (value) => value.itemsFor(LeaderboardScope.global),
      ),
    );
    final rivals = context
        .select<LeaderboardProvider, List<RivalLeaderboardEntry>>(
          (value) => value.rivals,
        );
    final loading = context.select<LeaderboardProvider, bool>(
      (value) => value.isLoading,
    );
    final error = context.select<LeaderboardProvider, Object?>(
      (value) => value.errorFor(LeaderboardScope.global),
    );
    final rivalsError = context.select<LeaderboardProvider, Object?>(
      (value) => value.rivalsError,
    );
    final currentUserId = context.select<LeaderboardProvider, int?>(
      (value) => value.currentUserId,
    );
    final currentUserLoadout = _currentUserLocalLoadout(context);
    final currentUserTarget = _maybeWatch<CosmeticTargetProvider>(
      context,
    )?.target;
    final weekly = _maybeWatch<WeeklyFeaturedProvider>(context);
    final avatarProvider = _maybeWatch<AvatarProvider>(context);
    if (weekly != null && avatarProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        weekly.refreshCompletionFromInventory(avatarProvider.inventory);
      });
    }
    final weeklyCompletionLabel =
        weekly?.completedActiveSet == true && weekly?.activeSet != null
        ? weekly!.activeSet!.leaderboardAccentLabel
        : null;
    final playerTitle =
        _maybeWatch<PlayerIdentityProvider>(context)?.featuredTitle;
    final isLoadingRivals = context.select<LeaderboardProvider, bool>(
      (value) => value.isLoadingRivals,
    );
    final showFooter =
        isLoadingRivals || rivals.isNotEmpty || rivalsError != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const LeaderboardHeader(),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: AppScale.centeredContentConstraints(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.sm,
                  AppSpacing.base,
                  AppSpacing.sm,
                ),
                child: Column(
                  children: <Widget>[
                    const LeaderboardTabs(
                      selected: LeaderboardTabDestination.users,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    LeaderboardSearchBar(
                      onSearch: (query) => setState(() => _query = query),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    PeriodSelector(
                      value: period,
                      onChanged: (newPeriod) {
                        context.read<LeaderboardProvider>().changePeriod(
                          newPeriod,
                          board: LeaderboardBoard.users,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: loading && items.isEmpty
                ? _buildShimmerLoading()
                : error != null && items.isEmpty
                ? _LeaderboardErrorState(onRetry: _refreshUsers)
                : items.isEmpty
                ? RefreshIndicator(
                    onRefresh: _refreshUsers,
                    child: ListView(
                      children: const <Widget>[
                        SizedBox(height: 120),
                        Center(child: Text('No leaderboard data yet.')),
                      ],
                    ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: AppScale.centeredContentConstraints(),
                      child: RefreshIndicator(
                        onRefresh: _refreshUsers,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount:
                              items.length +
                              (showFooter ? 1 : 0) +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < items.length) {
                              final item = items[index];
                              final previousRank =
                                  _previousRanks[item.userId] ?? item.rank;
                              _previousRanks[item.userId] = item.rank;

                              return RepaintBoundary(
                                child: GestureDetector(
                                  onTap: () => context.openUserProfile(
                                    item.userId.toString(),
                                  ),
                                  child: AnimatedLeaderboardItem(
                                    item: item,
                                    isCurrentUser: item.userId == currentUserId,
                                    previousRank: previousRank,
                                    subtitle: '${item.score} XP',
                                    currentUserLoadout: currentUserLoadout,
                                    currentUserTarget: currentUserTarget,
                                    weeklyFeaturedCompletionLabel:
                                        weeklyCompletionLabel,
                                    playerTitle: item.userId == currentUserId
                                        ? playerTitle
                                        : null,
                                  ),
                                ),
                              );
                            }

                            final footerIndex = index - items.length;
                            if (showFooter && footerIndex == 0) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  top: AppSpacing.sm,
                                  bottom: AppSpacing.sm,
                                ),
                                child: MiniLeaderboard(
                                  entries: rivals,
                                  currentUserId: currentUserId,
                                  currentUserLoadout: currentUserLoadout,
                                  currentUserTarget: currentUserTarget,
                                  weeklyFeaturedCompletionLabel:
                                      weeklyCompletionLabel,
                                  isLoading: isLoadingRivals,
                                  errorMessage: rivalsError?.toString(),
                                  onRetry: () => context
                                      .read<LeaderboardProvider>()
                                      .fetchRivals(),
                                ),
                              );
                            }

                            return Padding(
                              padding: EdgeInsets.all(AppSpacing.base),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  SocialCosmeticLoadout? _currentUserLocalLoadout(BuildContext context) {
    final auth = _maybeWatch<AuthProvider>(context);
    final avatar = _maybeWatch<AvatarProvider>(context);
    if (avatar == null) return null;

    final loadout = SocialCosmeticLoadout.fromLocal(
      userId: auth?.userId ?? 'local',
      avatar: avatar.avatarConfig,
      inventory: avatar.inventory,
      catalog: avatar.catalog,
    );
    return loadout.hasEquippedCosmetics || loadout.hasRecentRareUnlock
        ? loadout
        : null;
  }

  T? _maybeWatch<T>(BuildContext context) {
    try {
      return context.watch<T>();
    } catch (_) {
      return null;
    }
  }
}

class _LeaderboardErrorState extends StatelessWidget {
  const _LeaderboardErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('An error occurred. Please try again.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
