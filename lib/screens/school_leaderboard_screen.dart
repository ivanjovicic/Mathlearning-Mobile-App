// Refactored SchoolLeaderboardScreen to improve modularity and maintainability
// Extracted reusable components and optimized state management

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/school_leaderboard_provider.dart';
import '../theme/astrax_theme.dart';
import '../widgets/leaderboard_item.dart';
import '../widgets/my_school_card.dart';
import '../widgets/refreshable_list.dart';
import '../widgets/school_leaderboard_detail_sheet.dart';
import '../widgets/ui/app_section.dart';
import '../widgets/ui/state_scaffold.dart';

class SchoolLeaderboardScreen extends StatefulWidget {
  const SchoolLeaderboardScreen({super.key});

  @override
  State<SchoolLeaderboardScreen> createState() =>
      _SchoolLeaderboardScreenState();
}

class _SchoolLeaderboardScreenState extends State<SchoolLeaderboardScreen> {
  final ScrollController _scroll = ScrollController();
  String range = 'weekly';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      Provider.of<SchoolLeaderboardProvider>(
        context,
        listen: false,
      ).reload(range);
    });

    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final threshold = _scroll.position.maxScrollExtent - 320;
      if (_scroll.position.pixels > threshold) {
        Provider.of<SchoolLeaderboardProvider>(
          context,
          listen: false,
        ).loadMore(range);
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
    final loadedCount = items.length;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: AppSection(
                  title: 'Rangiranje skola',
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poredi performanse skola kroz vreme.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetricBadge(
                            icon: Icons.groups_rounded,
                            label: '$loadedCount schools loaded',
                          ),
                          _MetricBadge(
                            icon: Icons.calendar_view_week_rounded,
                            label: range == 'weekly'
                                ? 'Weekly competition'
                                : 'All-time standings',
                          ),
                          if (mySchool != null)
                            _MetricBadge(
                              icon: Icons.flag_rounded,
                              label: 'Your school #${mySchool.rank}',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StateScaffold(
                  isLoading: loading && items.isEmpty,
                  isEmpty: !loading && items.isEmpty && error == null,
                  error: error?.toString(),
                  onRetry: () => provider.reload(range),
                  emptyTitle: 'Nema rang liste',
                  emptySubtitle: 'Povuci nadole da osvezis podatke.',
                  emptyIcon: Icons.school_outlined,
                  child: RefreshableList(
                    controller: _scroll,
                    items: items,
                    loading: loading,
                    hasMore: hasMore,
                    error: error,
                    onRefresh: () => provider.reload(range),
                    onLoadMore: () => provider.loadMore(range),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final detail = await provider.loadDetail(
                            it.schoolId,
                            range,
                          );
                          final history = detail?.history.isNotEmpty == true
                              ? detail!.history
                              : await provider.loadHistory(it.schoolId, range);
                          if (!context.mounted) return;
                          await SchoolLeaderboardDetailSheet.show(
                            context,
                            school: detail?.school ?? it,
                            history: history,
                          );
                        },
                        child: SchoolLeaderboardTile(item: it),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (mySchool != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: MySchoolCard(school: mySchool),
            ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
