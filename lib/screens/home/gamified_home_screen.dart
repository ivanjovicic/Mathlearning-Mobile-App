import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_i18n.dart';
import '../../models/topic_item.dart';
import '../../state/auth_provider.dart';
import '../../state/coin_provider.dart';
import '../../state/learning_path_provider.dart';
import '../../state/progress_provider.dart';
import '../../widgets/animated_xp_bar.dart';
import '../../widgets/level_up_animation.dart';
import '../../widgets/offline_status_widget.dart';
import '../../widgets/streak_badge_presenter.dart';
import '../../widgets/theme_accessibility_mini_preview.dart';
import '../../widgets/ui/app_section.dart';
import '../../widgets/ui/state_scaffold.dart';
import '../quiz/pick_topic_screen.dart';

class GamifiedHomeScreen extends StatefulWidget {
  const GamifiedHomeScreen({super.key});

  @override
  State<GamifiedHomeScreen> createState() => _GamifiedHomeScreenState();
}

class _GamifiedHomeScreenState extends State<GamifiedHomeScreen> {
  static const int _dailyGoalTarget = 20;
  String? _error;
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrapHome();
  }

  Future<void> _bootstrapHome() async {
    try {
      if (!mounted) return;

      final progress = Provider.of<ProgressProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);

      progress.token = auth.token;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        coinProvider.loadCoinsAndHints();
      });

      progress.onLevelUp = () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => LevelUpAnimation(
            level: progress.level,
            onFinished: () {
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
        );
      };

      await progress.loadProgress();
      await progress.rollDailyStreakIfNeeded();
      if (!mounted) return;
      await progress.loadTopics();
      setState(() => _error = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isBootstrapping = false);
      }
    }
  }

  void _retryBootstrap() {
    setState(() {
      _isBootstrapping = true;
      _error = null;
    });
    _bootstrapHome();
  }

  TopicProgress? _findRecommendedTopic(ProgressProvider progress) {
    for (final topic in progress.topics) {
      final unlocked = topic.unlocked && progress.level >= topic.requiredLevel;
      if (unlocked) {
        return topic;
      }
    }
    return null;
  }

  int _resolveQuizTopicId(ProgressProvider progress) {
    final recommended = _findRecommendedTopic(progress);
    if (recommended != null) {
      return recommended.topicId;
    }

    if (progress.topics.isNotEmpty) {
      return progress.topics.first.topicId;
    }

    return 1;
  }

  void _openTopicPicker(ProgressProvider progress) {
    if (progress.topics.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.noTopicsAvailable())));
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final topicPalette = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];

    final mapped = <TopicItem>[];
    for (var i = 0; i < progress.topics.length; i++) {
      final topic = progress.topics[i];
      final locked = !topic.unlocked || progress.level < topic.requiredLevel;
      mapped.add(
        TopicItem(
          id: topic.topicId,
          name: topic.name,
          accuracy: locked ? 0 : 100,
          locked: locked,
          icon: Icons.auto_stories,
          color: topicPalette[i % topicPalette.length],
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PickTopicScreen(topics: mapped)),
    );
  }

  void _onBottomNavTap(int index, ProgressProvider progress) {
    switch (index) {
      case 0:
        return;
      case 1:
        context.push('/quiz', extra: _resolveQuizTopicId(progress));
        return;
      case 2:
        context.go('/leaderboard');
        return;
      case 3:
        context.go('/profile');
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = Provider.of<ProgressProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final username = auth.username?.trim();
    final dailyDone = progress.totalAttempts % _dailyGoalTarget;
    final recommendedTopic = _findRecommendedTopic(progress);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: StateScaffold(
        isLoading: _isBootstrapping,
        error: _error,
        onRetry: _retryBootstrap,
        isEmpty: !_isBootstrapping && _error == null && progress.topics.isEmpty,
        emptyTitle: "Nema dostupnih tema",
        emptySubtitle: "Odaberi temu kasnije kada podaci budu dostupni.",
        emptyIcon: Icons.auto_stories_outlined,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: OfflineStatusWidget(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.homeArena,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                t.hello(
                  username?.isNotEmpty == true ? username! : t.fallbackPlayer,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Demo mode banner
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  if (!auth.isDemoMode) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onPrimaryContainer,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Demo režim - test podaci",
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 4),
              AppSection(
                title: t.launchNextQuiz,
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHeroPanel(
                  context: context,
                  level: progress.level,
                  xp: progress.xp,
                  xpToNextLevel: progress.xpToNextLevel,
                  topicName:
                      recommendedTopic?.name ?? t.chooseTopicAndContinueQuiz,
                  onStart: () {
                    context.push('/quiz', extra: _resolveQuizTopicId(progress));
                  },
                ),
              ),
              const Center(child: StreakBadgePresenter()),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildStatChip(
                    context: context,
                    icon: Icons.local_fire_department,
                    label: t.streakInRowDays(progress.streak),
                    color: colorScheme.secondaryContainer,
                    onColor: colorScheme.onSecondaryContainer,
                  ),
                  Consumer<CoinProvider>(
                    builder: (context, coinProvider, _) {
                      return _buildStatChip(
                        context: context,
                        icon: Icons.monetization_on,
                        label: t.coins(coinProvider.coins),
                        color: colorScheme.tertiaryContainer,
                        onColor: colorScheme.onTertiaryContainer,
                      );
                    },
                  ),
                  _buildStatChip(
                    context: context,
                    icon: Icons.flag_circle_outlined,
                    label: t.dailyGoalShort(dailyDone, _dailyGoalTarget),
                    color: colorScheme.primaryContainer,
                    onColor: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ThemeAccessibilityMiniPreview(
                title: t.arenaAccessibilityPreview,
                compact: true,
              ),
              const SizedBox(height: 14),
              _LearningPathBanner(),
              const SizedBox(height: 14),
              AppSection(
                title: t.missionTopics,
                trailing: TextButton.icon(
                  onPressed: progress.topics.isEmpty
                      ? null
                      : () => _openTopicPicker(progress),
                  icon: const Icon(Icons.auto_stories),
                  label: Text(t.allTopics),
                ),
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: progress.topics.map((topic) {
                    final locked =
                        !topic.unlocked || progress.level < topic.requiredLevel;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(
                          locked ? Icons.lock_outline : Icons.play_circle_fill,
                          color: locked
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.primary,
                        ),
                        title: Text(
                          topic.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          locked
                              ? t.unlockAtLevel(topic.requiredLevel)
                              : t.readyToPlay,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: locked
                              ? null
                              : () {
                                  context.push('/quiz', extra: topic.topicId);
                                },
                          child: Text(t.play),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
        onDestinationSelected: (index) => _onBottomNavTap(index, progress),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.quiz_outlined),
            selectedIcon: const Icon(Icons.quiz),
            label: t.navQuiz,
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: t.navRank,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t.navProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPanel({
    required BuildContext context,
    required int level,
    required int xp,
    required int xpToNextLevel,
    required String topicName,
    required VoidCallback onStart,
  }) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.level(level),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            topicName,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedXpBar(currentXp: xp, maxXp: xpToNextLevel),
          const SizedBox(height: 6),
          Text(
            t.nextLevelHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: Text(t.launchNextQuiz),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color onColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: onColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPathBanner extends StatelessWidget {
  const _LearningPathBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final provider = context.watch<LearningPathProvider>();
    final recommended = provider.recommended;
    final String title =
        recommended != null ? recommended.topicName : 'Start your path';
    final String subtitle = recommended != null
        ? (recommended.recommendationReason ?? 'Continue where you left off')
        : 'Build skills step by step';

    return GestureDetector(
      onTap: () => context.go('/learning-path'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer, cs.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.route_rounded, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Path',
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.primary),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.04, end: 0);
  }
}
