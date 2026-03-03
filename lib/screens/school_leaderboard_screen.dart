// Refactored SchoolLeaderboardScreen to improve modularity and maintainability
// Extracted reusable components and optimized state management

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/school_leaderboard_models.dart';
import '../state/school_leaderboard_provider.dart';
import '../theme/astrax_theme.dart';
import '../widgets/leaderboard_item.dart';
import '../widgets/my_school_card.dart';
import '../widgets/refreshable_list.dart';

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
                child: RefreshableList(
                  items: items,
                  loading: loading,
                  hasMore: hasMore,
                  error: error,
                  onRefresh: () => provider.reload(range),
                  onLoadMore: () => provider.loadMore(range),
                  itemBuilder: (context, index) => LeaderboardItem(item: items[index]),
                ),
              ),
            ],
          ),
          if (mySchool != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: MySchoolCard(mySchool: mySchool),
            ),
        ],
      ),
    );
  }
}

