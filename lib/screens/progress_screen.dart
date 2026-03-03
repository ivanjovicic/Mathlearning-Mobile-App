import 'package:flutter/material.dart';

import '../models/progress_overview.dart';
import '../services/api_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressOverview? _progress;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }
  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final progress = await ApiService().getProgressOverview();
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Unable to load progress', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadProgress, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final progress = _progress;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: progress == null
            ? const Center(child: Text('No progress yet'))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _OverviewHero(progress: progress),
                    const SizedBox(height: 16),
                    _StatsGrid(progress: progress),
                    const SizedBox(height: 16),
                    _CompletionSection(progress: progress),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  final ProgressOverview progress;

  const _OverviewHero({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final completion = progress.totalQuizzes > 0
        ? progress.completedQuizzes / progress.totalQuizzes
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.surfaceContainerHighest,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ukupan napredak",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: completion),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                borderRadius: BorderRadius.circular(20),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            "${progress.completedQuizzes}/${progress.totalQuizzes} završeno",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ProgressOverview progress;

  const _StatsGrid({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return GridView.count(
          crossAxisCount: isTablet ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            AppStatCard(
              label: "Ukupno kvizova",
              value: progress.totalQuizzes.toString(),
              icon: Icons.quiz_rounded,
              color: cs.primary,
            ),
            AppStatCard(
              label: "Završeno",
              value: progress.completedQuizzes.toString(),
              icon: Icons.check_circle_rounded,
              color: cs.tertiary,
            ),
            AppStatCard(
              label: "Prosek",
              value: "${(progress.averageScore * 100).toStringAsFixed(1)}%",
              icon: Icons.analytics_rounded,
              color: cs.secondary,
            ),
            AppStatCard(
              label: "Najbolji",
              value: "${(progress.bestScore * 100).toStringAsFixed(1)}%",
              icon: Icons.star_rounded,
              color: Colors.amber,
            ),
          ],
        );
      },
    );
  }
}

class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cs.surfaceContainerHighest,
        boxShadow: [
            BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _CompletionSection extends StatelessWidget {
  final ProgressOverview progress;

  const _CompletionSection({required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Završeni zadaci',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${progress.completedQuizzes} / ${progress.totalQuizzes} kvizova',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.totalQuizzes > 0
                    ? progress.completedQuizzes / progress.totalQuizzes
                    : 0,
                minHeight: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
