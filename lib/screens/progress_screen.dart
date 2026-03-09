import 'package:flutter/material.dart';

import '../models/progress_overview.dart';
import '../services/api_service.dart';
import '../theme/app_scale.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../widgets/ui/app_section.dart';
import '../widgets/ui/state_scaffold.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressOverview? _progress;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final progress = await ApiService().getProgressOverview();
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: StateScaffold(
        isLoading: _isLoading,
        error: _error,
        onRetry: _loadProgress,
        isEmpty: !_isLoading && _error == null && progress == null,
        emptyTitle: 'No quizzes completed yet',
        emptySubtitle: 'Start your first practice!',
        emptyIcon: Icons.insights_outlined,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: AppScale.centeredContentConstraints(),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.base),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _OverviewHero(progress: progress!),
                      SizedBox(height: AppSpacing.base),
                      AppSection(
                        title: 'Kljucne metrike',
                        padding: EdgeInsets.only(bottom: AppSpacing.base),
                        child: _StatsGrid(progress: progress),
                      ),
                      AppSection(
                        title: 'Zavrsetak',
                        padding: EdgeInsets.zero,
                        child: _CompletionSection(progress: progress),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppScale.radius(28)),
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
            'Ukupan napredak',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: AppSpacing.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: completion),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: AppScale.s(12),
                borderRadius: BorderRadius.circular(AppScale.radius(20)),
              );
            },
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '${progress.completedQuizzes}/${progress.totalQuizzes} zavrseno',
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

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppScale.s(180).clamp(160.0, 220.0).toDouble(),
        crossAxisSpacing: AppSpacing.base,
        mainAxisSpacing: AppSpacing.base,
        childAspectRatio: 1.08,
      ),
      children: [
        AppStatCard(
          label: 'Ukupno kvizova',
          value: progress.totalQuizzes.toString(),
          icon: Icons.quiz_rounded,
          color: cs.primary,
        ),
        AppStatCard(
          label: 'Zavrseno',
          value: progress.completedQuizzes.toString(),
          icon: Icons.check_circle_rounded,
          color: cs.tertiary,
        ),
        AppStatCard(
          label: 'Prosek',
          value: '${(progress.averageScore * 100).toStringAsFixed(1)}%',
          icon: Icons.analytics_rounded,
          color: cs.secondary,
        ),
        AppStatCard(
          label: 'Najbolji',
          value: '${(progress.bestScore * 100).toStringAsFixed(1)}%',
          icon: Icons.star_rounded,
          color: Colors.amber,
        ),
      ],
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
      padding: EdgeInsets.all(AppScale.s(18)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppScale.radius(24)),
        color: cs.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: AppScale.s(20),
            offset: Offset(0, AppScale.s(10)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppScale.icon(24, min: 22, max: 32)),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: AppSpacing.xs),
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
        Text('Zavrseni zadaci', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppScale.s(14)),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppScale.radius(14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${progress.completedQuizzes} / ${progress.totalQuizzes} kvizova',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: progress.totalQuizzes > 0
                    ? progress.completedQuizzes / progress.totalQuizzes
                    : 0,
                minHeight: AppScale.s(8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
