import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../state/leaderboard_provider.dart';
import '../theme/astrax_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  String range = "weekly"; // weekly | allTime

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LeaderboardProvider>(context, listen: false);
      provider.loadGlobal(range);
      provider.loadFriends(range);
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = Provider.of<LeaderboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AstraXTheme.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: AstraXTheme.neonPurple, size: 22),
              const SizedBox(width: 8),
              const Text(
                "Rang lista",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Globalno"),
              Tab(text: "Prijatelji"),
            ],
          ),
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: colorScheme.surface,
                value: range,
                items: [
                  DropdownMenuItem(
                    value: "weekly",
                    child: Text(
                      "Nedeljno",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "allTime",
                    child: Text(
                      "Ukupno",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => range = v);
                  leaderboard.loadGlobal(v);
                  leaderboard.loadFriends(v);
                },
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildList(
              leaderboard.global,
              leaderboard.isLoading,
              auth.userId != null ? int.tryParse(auth.userId!) : null,
              colorScheme,
              range,
              reduceMotion,
              onRefresh: () => leaderboard.loadGlobal(range),
              myRankOutsideList: leaderboard.myGlobalRank,
            ),
            _buildList(
              leaderboard.friends,
              leaderboard.isLoading,
              auth.userId != null ? int.tryParse(auth.userId!) : null,
              colorScheme,
              range,
              reduceMotion,
              onRefresh: () => leaderboard.loadFriends(range),
              myRankOutsideList: leaderboard.myFriendsRank,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<LeaderboardEntry> items,
    bool loading,
    int? myUserId,
    ColorScheme colorScheme,
    String range,
    bool reduceMotion, {
    Future<void> Function()? onRefresh,
    LeaderboardEntry? myRankOutsideList,
  }) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              "Nema podataka.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      );
    }

    // Total items = list + separator + my rank row (if outside list)
    final showMyRank = myRankOutsideList != null;
    final totalItems = items.length + (showMyRank ? 2 : 0);

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: totalItems,
        itemBuilder: (_, i) {
          // Regular list items
          if (i < items.length) {
            return _buildRow(
              items[i],
              items[i].userId == myUserId,
              colorScheme,
              range,
              reduceMotion,
              i,
            );
          }

          // Separator dots
          if (i == items.length && showMyRank) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            );
          }

          // My rank row (outside top 50)
          if (i == items.length + 1 && showMyRank) {
            return _buildRow(
              myRankOutsideList,
              true,
              colorScheme,
              range,
              reduceMotion,
              i,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRow(
    LeaderboardEntry e,
    bool isMe,
    ColorScheme colorScheme,
    String range,
    bool reduceMotion,
    int index,
  ) {
    final rankColor = _rankColor(e.rank, colorScheme);
    final isTop = e.rank <= 3;
    final color = isMe ? colorScheme.primary : colorScheme.onSurface;
    final bg = isMe
        ? colorScheme.primaryContainer.withValues(alpha: 0.45)
        : colorScheme.surface.withValues(alpha: 0.7);
    final xpValue = range == "weekly" ? e.weeklyXp : e.xp;

    final row = Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isTop
            ? LinearGradient(colors: [rankColor.withValues(alpha: 0.18), bg])
            : null,
        color: isTop ? null : bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop
              ? rankColor
              : (isMe ? colorScheme.primary : colorScheme.outline),
          width: 2,
        ),
        boxShadow: isTop
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          _rankBadge(e.rank, colorScheme),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          "Ti",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statChip(
                      icon: Icons.local_fire_department,
                      value: "${e.streak}",
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      icon: Icons.bolt,
                      value: "$xpValue XP",
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      icon: Icons.emoji_events_outlined,
                      value: "Nivo ${e.level}",
                      color: rankColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) {
      return row;
    }

    return row
        .animate()
        .fadeIn(duration: 220.ms, delay: (index * 40).ms)
        .moveY(begin: 14, duration: 260.ms);
  }

  Widget _rankBadge(int rank, ColorScheme colorScheme) {
    final rankColor = _rankColor(rank, colorScheme);
    final isTop = rank <= 3;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rankColor.withValues(alpha: isTop ? 0.2 : 0.12),
        border: Border.all(color: rankColor.withValues(alpha: 0.8), width: 2),
      ),
      child: Center(
        child: isTop
            ? Icon(Icons.emoji_events, color: rankColor, size: 24)
            : Text(
                "$rank",
                style: TextStyle(
                  color: rankColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Color _rankColor(int rank, ColorScheme colorScheme) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD54F);
      case 2:
        return Colors.blueGrey.shade200;
      case 3:
        return const Color(0xFFB87333);
      default:
        return colorScheme.onSurface.withValues(alpha: 0.7);
    }
  }

  Widget _statChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
