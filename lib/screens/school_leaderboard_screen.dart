import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/school_leaderboard_models.dart';
import '../state/school_leaderboard_provider.dart';
import '../theme/astrax_theme.dart';

class SchoolLeaderboardScreen extends StatefulWidget {
  const SchoolLeaderboardScreen({super.key});

  @override
  State<SchoolLeaderboardScreen> createState() => _SchoolLeaderboardScreenState();
}

class _SchoolLeaderboardScreenState extends State<SchoolLeaderboardScreen> {
  final ScrollController _scroll = ScrollController();
  String range = 'weekly';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      Provider.of<SchoolLeaderboardProvider>(context, listen: false).reload(range);
    });

    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final threshold = _scroll.position.maxScrollExtent - 320;
      if (_scroll.position.pixels > threshold) {
        Provider.of<SchoolLeaderboardProvider>(context, listen: false).loadMore(range);
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
    final provider = Provider.of<SchoolLeaderboardProvider>(context);
    final items = provider.paging.items;
    final loading = provider.paging.isLoading;
    final hasMore = provider.paging.hasMore;
    final mySchool = provider.mySchool;
    final error = provider.error;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AstraXTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('School vs School'),
        centerTitle: true,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: colorScheme.surface,
              value: range,
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'allTime', child: Text('All time')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => range = v);
                provider.reload(v);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildBody(
                  context,
                  items: items,
                  loading: loading,
                  hasMore: hasMore,
                  error: error,
                  bottomPadding: mySchool != null ? 124 : 0,
                  onRefresh: () => provider.reload(range),
                  onLoadMore: () => provider.loadMore(range),
                ),
              ),
            ],
          ),
          if (mySchool != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildMySchoolCard(mySchool),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<SchoolAggregateItem> items,
    required bool loading,
    required bool hasMore,
    required Object? error,
    required double bottomPadding,
    required Future<void> Function() onRefresh,
    required VoidCallback onLoadMore,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (loading && items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (error != null && items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          controller: _scroll,
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
              'Ne mogu da ucitam rang listu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 10),
            Text(
              'Povuci nadole za retry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.school_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Nema podataka.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        itemCount: items.length + (loading || hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < items.length) {
            return _buildSchoolItem(items[index]);
          }

          if (loading) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            );
          }

          if (hasMore) {
            onLoadMore();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Ucitam jos...',
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
                'Kraj liste.',
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

  Widget _buildSchoolItem(SchoolAggregateItem school) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              "#${school.rank}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              school.schoolName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${school.score} XP",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                "${school.members} students",
                style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w700),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMySchoolCard(SchoolAggregateItem mySchool) {
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
                      child: Text(
                        "#${mySchool.rank}",
                        style: const TextStyle(
                          color: AstraXTheme.textPrimary,
                          fontWeight: FontWeight.w900,
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
                        Text(
                          mySchool.schoolName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AstraXTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${mySchool.score} XP  •  ${mySchool.members} students",
                          style: TextStyle(
                            color: AstraXTheme.textSecondary.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.school,
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

