import 'package:flutter/material.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:provider/provider.dart';

import '../navigation/navigation_extensions.dart';
import '../state/auth_provider.dart';
import '../state/leaderboard_provider.dart';
import '../theme/app_scale.dart';
import '../theme/astrax_theme.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../widgets/animated_leaderboard_item.dart';
import '../widgets/leaderboard_header.dart';
import '../widgets/leaderboard_search_bar.dart';
import '../widgets/period_selector.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool autoLoad;

  const LeaderboardScreen({super.key, this.autoLoad = true});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  String range = "weekly"; // weekly | allTime
  LeaderboardScope scope = LeaderboardScope.global;
  final ScrollController _scroll = ScrollController();
  bool isLoadingMore = false;
  Map<int, int> previousRanks = {};

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        Provider.of<LeaderboardProvider>(context, listen: false).currentUserId =
            int.tryParse(auth.userId ?? '');
      } catch (_) {}
      if (widget.autoLoad) {
        Provider.of<LeaderboardProvider>(context, listen: false)
            .loadGlobal(range);
      }
    });

    _scroll.addListener(() {
      if (!_scroll.hasClients || isLoadingMore) return;
      final threshold = _scroll.position.maxScrollExtent - 320;
      if (_scroll.position.pixels > threshold) {
        setState(() => isLoadingMore = true);
        final provider = Provider.of<LeaderboardProvider>(
          context,
          listen: false,
        );
        provider.loadMore(scope, range).then((_) {
          setState(() => isLoadingMore = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
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
    final provider = Provider.of<LeaderboardProvider>(context);
    final items = provider.itemsFor(scope);
    final isLoading = provider.paging.isLoading;

    return Scaffold(
      backgroundColor: AstraXTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const LeaderboardHeader(),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: AppScale.centeredContentConstraints(),
                  child: Column(
                    children: [
                      SizedBox(height: AppSpacing.xs),
                      LeaderboardSearchBar(
                        onSearch: (query) {
                          Provider.of<LeaderboardProvider>(
                            context,
                            listen: false,
                          ).searchLeaderboard(query, scope, range);
                        },
                      ),
                      PeriodSelector(
                        value: range,
                        onChanged: (newRange) {
                          if (newRange == null) return;
                          setState(() => range = newRange);
                          Provider.of<LeaderboardProvider>(
                            context,
                            listen: false,
                          ).reloadScope(scope, newRange);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: isLoading && items.isEmpty
                    ? _buildShimmerLoading()
                    : items.isEmpty && !provider.isLoading && !provider.hasError
                        ? RefreshIndicator(
                            onRefresh: () =>
                                provider.reloadScope(scope, range),
                            child: ListView(
                              children: const [
                                Center(child: Text('Nema podataka.')),
                              ],
                            ),
                          )
                        : Center(
                            child: ConstrainedBox(
                              constraints: AppScale.centeredContentConstraints(),
                              child: ListView.builder(
                                controller: _scroll,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.base,
                                  vertical: AppSpacing.sm,
                                ),
                                itemCount: items.length + (isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index < items.length) {
                                    final item = items[index];
                                    final previousRank =
                                        previousRanks[item.userId] ?? item.rank;
                                    previousRanks[item.userId] = item.rank;

                                    return RepaintBoundary(
                                      child: GestureDetector(
                                        onTap: () => context.openUserProfile(
                                          item.userId.toString(),
                                        ),
                                        child: AnimatedLeaderboardItem(
                                          item: item,
                                          isCurrentUser:
                                              item.userId ==
                                              provider.currentUserId,
                                          previousRank: previousRank,
                                          subtitle: '${item.score} XP',
                                        ),
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
            ],
          ),
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator()),
          if (provider.hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('An error occurred. Please try again.'),
                  ElevatedButton(
                    onPressed: () => provider.retry(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
