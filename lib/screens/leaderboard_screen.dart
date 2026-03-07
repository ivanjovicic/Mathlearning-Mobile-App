import 'package:flutter/material.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:provider/provider.dart';

import '../state/leaderboard_provider.dart';
import '../theme/astrax_theme.dart';
import '../widgets/animated_leaderboard_item.dart';
import '../widgets/leaderboard_header.dart';
import '../widgets/leaderboard_search_bar.dart';
import '../widgets/period_selector.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

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
      final provider = Provider.of<LeaderboardProvider>(context, listen: false);
      provider.loadGlobal(range);
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
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return const ListTileShimmer(isRectBox: true, isDisabledAvatar: false);
      },
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
              LeaderboardSearchBar(
                onSearch: (query) {
                  Provider.of<LeaderboardProvider>(
                    context,
                    listen: false,
                  ).searchLeaderboard(query, scope, range);
                },
              ),
              const PeriodSelector(),
              Expanded(
                child: isLoading && items.isEmpty
                    ? _buildShimmerLoading()
                    : ListView.builder(
                        controller: _scroll,
                        itemCount: items.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < items.length) {
                            final item = items[index];
                            final previousRank =
                                previousRanks[item.userId] ?? item.rank;
                            previousRanks[item.userId] = item.rank;

                            return RepaintBoundary(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(
                                        userId: item.userId,
                                      ),
                                    ),
                                  );
                                },
                                child: AnimatedLeaderboardItem(
                                  item: item,
                                  isCurrentUser:
                                      item.userId == provider.currentUserId,
                                  previousRank: previousRank,
                                  title: 'Rank ${item.rank}',
                                  subtitle: '${item.score} XP',
                                ),
                              ),
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
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
          if (items.isEmpty && !provider.isLoading && !provider.hasError)
            const Center(child: Text('No leaderboard data available.')),
        ],
      ),
    );
  }
}
