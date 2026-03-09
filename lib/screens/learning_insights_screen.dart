import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/path_node.dart';
import '../state/adaptive_provider.dart';
import '../state/learning_path_provider.dart';
import '../widgets/adaptive_difficulty_badge.dart';
import '../widgets/mastery_ring_indicator.dart';
import '../widgets/review_due_pill.dart';
import '../widgets/topic_mastery_bar.dart';

class LearningInsightsScreen extends StatefulWidget {
  const LearningInsightsScreen({super.key});

  @override
  State<LearningInsightsScreen> createState() => _LearningInsightsScreenState();
}

class _LearningInsightsScreenState extends State<LearningInsightsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdaptiveProvider>().loadWeakTopics();
      context.read<LearningPathProvider>().loadPath();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AdaptiveProvider>().loadWeakTopics(),
      context.read<LearningPathProvider>().loadPath(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final adaptive = context.watch<AdaptiveProvider>();
    final pathProvider = context.watch<LearningPathProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Insights'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Mastery'),
            Tab(text: 'Weak Topics'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: TabBarView(
          controller: _tabs,
          children: [
            _OverviewTab(pathProvider: pathProvider),
            _MasteryTab(pathProvider: pathProvider, adaptiveProvider: adaptive),
            _WeakTopicsTab(adaptiveProvider: adaptive),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/learn'),
        icon: const Icon(Icons.route_rounded),
        label: const Text('Open Map'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
    );
  }
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.pathProvider});
  final LearningPathProvider pathProvider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final nodes = pathProvider.nodes;

    if (pathProvider.isLoading && nodes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final completed = nodes
        .where((n) => n.state == PathNodeState.completed)
        .length;
    final total = nodes.length;
    final avgMastery = total == 0
        ? 0.0
        : nodes.fold<double>(0, (sum, n) => sum + n.mastery) / total;
    final dueCount = pathProvider.dueReviewCount;
    final recommended = pathProvider.recommended;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // Summary stats row
        Row(
          children: [
            _StatCard(
              icon: Icons.check_circle_outline,
              label: 'Completed',
              value: '$completed / $total',
              color: cs.primary,
            ).animate().fadeIn(delay: 0.ms).slideY(begin: 0.1),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.bar_chart_rounded,
              label: 'Avg Mastery',
              value: '${avgMastery.round()}%',
              color: cs.secondary,
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.replay_circle_filled_outlined,
              label: 'Due Reviews',
              value: '$dueCount',
              color: cs.tertiary,
            ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.1),
          ],
        ),
        const SizedBox(height: 24),

        // Up Next card
        if (recommended != null) ...[
          Text(
            'Up Next',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _NextNodeCard(
            node: recommended,
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.03),
          const SizedBox(height: 24),
        ],

        // Path progress bar
        Text(
          'Path Progress',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            minHeight: 12,
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          total == 0
              ? 'No nodes loaded yet'
              : '${(completed / total * 100).round()}% of your learning path done',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),

        if (pathProvider.isOfflineFallback) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: cs.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing offline path — connect to sync with your progress.',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextNodeCard extends StatelessWidget {
  const _NextNodeCard({required this.node});
  final PathNode node;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          MasteryRingIndicator(progress: node.mastery / 100, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.topicName,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (node.subtopicName != null)
                  Text(
                    node.subtopicName!,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AdaptiveDifficultyBadge(
                      difficulty: node.difficulty,
                      confidence: node.confidence,
                    ),
                    if (node.dueReviewCount > 0) ...[
                      const SizedBox(width: 6),
                      ReviewDuePill(count: node.dueReviewCount),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: cs.primary),
        ],
      ),
    );
  }
}

// ── Mastery tab ───────────────────────────────────────────────────────────────

class _MasteryTab extends StatelessWidget {
  const _MasteryTab({
    required this.pathProvider,
    required this.adaptiveProvider,
  });
  final LearningPathProvider pathProvider;
  final AdaptiveProvider adaptiveProvider;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final nodes = pathProvider.nodes;

    if (pathProvider.isLoading && nodes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Unique topics, sorted by mastery ascending
    final Map<String, int> topicMastery = {};
    for (final n in nodes) {
      topicMastery.update(
        n.topicName,
        (v) => (v + n.mastery.round()) ~/ 2,
        ifAbsent: () => n.mastery.round(),
      );
    }
    final sorted = topicMastery.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    if (sorted.isEmpty) {
      return Center(
        child: Text(
          'No mastery data yet',
          style: tt.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: sorted.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'All Topics',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          );
        }
        final entry = sorted[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TopicMasteryBar(
            topic: entry.key,
            mastery: entry.value.toDouble(),
          ).animate().fadeIn(delay: (i * 40).ms).slideX(begin: 0.04),
        );
      },
    );
  }
}

// ── Weak Topics tab ───────────────────────────────────────────────────────────

class _WeakTopicsTab extends StatelessWidget {
  const _WeakTopicsTab({required this.adaptiveProvider});
  final AdaptiveProvider adaptiveProvider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final weakTopics = adaptiveProvider.weakTopics;

    if (adaptiveProvider.isLoading && weakTopics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (weakTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 56, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              'No weak topics — great work!',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Keep practicing to maintain your mastery.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: weakTopics.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Needs Work',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${weakTopics.length} topic${weakTopics.length == 1 ? '' : 's'} below 70% accuracy',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        final item = weakTopics[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _WeakTopicTile(
            topic: item.topic,
            accuracy: item.accuracy,
          ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.04),
        );
      },
    );
  }
}

class _WeakTopicTile extends StatelessWidget {
  const _WeakTopicTile({required this.topic, required this.accuracy});
  final String topic;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pct = accuracy.clamp(0, 100).toDouble();
    final Color barColor = pct < 40
        ? cs.error
        : pct < 60
        ? cs.tertiary
        : cs.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${pct.round()}%',
                style: tt.labelLarge?.copyWith(
                  color: barColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}
