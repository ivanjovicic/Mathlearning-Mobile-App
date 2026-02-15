import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/leaderboard_models.dart';
import '../state/auth_provider.dart';
import '../state/leaderboard_provider.dart';
import '../state/user_profile_provider.dart';
import '../theme/astrax_theme.dart';
import '../widgets/leaderboard_scope_selector.dart';

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

  @override
  void initState() {
    super.initState();

    // In tests we want the initial fetch to start immediately, without requiring
    // extra frames for a post-frame callback.
    Future.microtask(() {
      if (!mounted) return;
      final provider = Provider.of<LeaderboardProvider>(context, listen: false);
      provider.loadGlobal(range);
    });

    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final threshold = _scroll.position.maxScrollExtent - 320;
      if (_scroll.position.pixels > threshold) {
        final provider =
            Provider.of<LeaderboardProvider>(context, listen: false);
        provider.loadMore(scope, range);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = Provider.of<LeaderboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final myUserId = auth.userId != null ? int.tryParse(auth.userId!) : null;
    final items = leaderboard.itemsFor(scope);
    final paging = leaderboard.pagingFor(scope);
    final me = leaderboard.meFor(scope);
    final error = leaderboard.errorFor(scope);

    UserProfileProvider? profileProvider;
    try {
      profileProvider = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      profileProvider = null;
    }
    final schoolId = profileProvider?.profile?.schoolId;
    final facultyId = profileProvider?.profile?.facultyId;

    final schoolEnabled = schoolId != null;
    final facultyEnabled = facultyId != null;
    if ((scope == LeaderboardScope.school && !schoolEnabled) ||
        (scope == LeaderboardScope.faculty && !facultyEnabled)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => scope = LeaderboardScope.global);
      });
    }

    return Scaffold(
      backgroundColor: AstraXTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              color: AstraXTheme.neonPurple,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              "Rang lista",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
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
                leaderboard.reloadScope(scope, v);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: LeaderboardScopeSelector(
                  selectedScope: scope.apiValue,
                  schoolId: schoolId,
                  facultyId: facultyId,
                  onChanged: (value) {
                    final next = _scopeFromString(value);
                    if (next == scope) return;
                    setState(() => scope = next);
                    if (_scroll.hasClients) _scroll.jumpTo(0);
                    leaderboard.reloadScope(next, range);
                  },
                ),
              ),
              Expanded(
                child: _buildList(
                  items,
                  paging,
                  myUserId,
                  colorScheme,
                  range,
                  reduceMotion,
                  error: error,
                  bottomPadding: me != null ? 128 : 0,
                  onRefresh: () => leaderboard.reloadScope(scope, range),
                  onLoadMore: () => leaderboard.loadMore(scope, range),
                ),
              ),
            ],
          ),
          if (me != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildMeSticky(me, colorScheme),
            ),
        ],
      ),
    );
  }

  LeaderboardScope _scopeFromString(String value) {
    switch (value) {
      case 'global':
        return LeaderboardScope.global;
      case 'school':
        return LeaderboardScope.school;
      case 'faculty':
        return LeaderboardScope.faculty;
      case 'friends':
        return LeaderboardScope.friends;
      default:
        return LeaderboardScope.global;
    }
  }

  Widget _buildList(
    List<LeaderboardItem> items,
    LeaderboardPagingController paging,
    int? myUserId,
    ColorScheme colorScheme,
    String range,
    bool reduceMotion, {
    Future<void> Function()? onRefresh,
    VoidCallback? onLoadMore,
    Object? error,
    double bottomPadding = 0,
  }) {
    final bool loading = paging.isLoading;
    final bool hasMore = paging.hasMore;

    if (loading && items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (error != null && items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.cloud_off,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              "Ne mogu da ucitam rang listu.",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 10),
            Text(
              "Povuci nadole za retry.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
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

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        itemCount: items.length + (loading || hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i < items.length) {
            final e = items[i];
            return _buildRow(
              e,
              e.userId == myUserId,
              colorScheme,
              reduceMotion,
              i,
            );
          }

          // Footer: loading / load-more trigger / end of list
          if (loading) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            );
          }
          if (hasMore) {
            // Fire-and-forget; guards are inside provider.
            onLoadMore?.call();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  "Ucitam jos...",
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                "Kraj liste.",
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(
    LeaderboardItem e,
    bool isMe,
    ColorScheme colorScheme,
    bool reduceMotion,
    int index,
  ) {
    final rankColor = _rankColor(e.rank, colorScheme);
    final isTop = e.rank <= 3;
    final color = isMe ? colorScheme.primary : colorScheme.onSurface;
    final bg = isMe
        ? colorScheme.primaryContainer.withValues(alpha: 0.45)
        : colorScheme.surface.withValues(alpha: 0.7);
    final xpValue = e.score;
    final streak = e.streakDays;

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
          _avatar(e, colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.displayName,
                        overflow: TextOverflow.ellipsis,
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
                      value: "$streak",
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      icon: Icons.bolt,
                      value: "$xpValue XP",
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return row;
  }

  Widget _avatar(LeaderboardItem e, ColorScheme colorScheme) {
    final name = e.displayName;
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final avatarUrl = e.avatarUrl;
    final border = Border.all(
      color: AstraXTheme.neonBlue.withValues(alpha: 0.35),
      width: 1.5,
    );

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AstraXTheme.panelLight,
        border: border,
        boxShadow: [
          BoxShadow(
            color: AstraXTheme.neonBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
        image: avatarUrl != null && avatarUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? null
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
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

  Widget _buildMeSticky(LeaderboardMe me, ColorScheme colorScheme) {
    final surface = AstraXTheme.panel.withValues(alpha: 0.72);
    final border = Border.all(color: Colors.white10);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18),
                border: border,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AstraXTheme.neonBlue.withValues(alpha: 0.25),
                          AstraXTheme.neonPurple.withValues(alpha: 0.18),
                        ],
                      ),
                      border: Border.all(
                        color: AstraXTheme.neonBlue.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: RankPop(
                        rank: me.rank,
                        builder: (_, r) => Text(
                          "#$r",
                          style: const TextStyle(
                            color: AstraXTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("You are #${me.rank}  •  ${me.score} XP",
                            style: const TextStyle(
                              color: AstraXTheme.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          "Top ${me.percentile}%",
                          style: TextStyle(
                            color: AstraXTheme.textSecondary.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (me.badges.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: me.badges
                                .take(6)
                                .map((b) => _BadgeChip(text: b))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: AstraXTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RankPop extends StatefulWidget {
  const RankPop({super.key, required this.rank, required this.builder});

  final int rank;
  final Widget Function(BuildContext, int) builder;

  @override
  State<RankPop> createState() => _RankPopState();
}

class _RankPopState extends State<RankPop> {
  int? _prev;

  @override
  void didUpdateWidget(covariant RankPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prev = oldWidget.rank;
  }

  @override
  Widget build(BuildContext context) {
    final from = _prev ?? widget.rank;
    final to = widget.rank;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: from, end: to),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => widget.builder(context, value),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String text;
  const _BadgeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
