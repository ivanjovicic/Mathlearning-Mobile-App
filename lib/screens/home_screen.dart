import 'package:flutter/material.dart';
import 'package:mathlearning/widgets/animated_xp_bar.dart';
import 'package:provider/provider.dart';

import '../l10n/app_i18n.dart';
import '../models/topic_item.dart';
import '../state/auth_provider.dart';
import '../state/coin_provider.dart';
import '../state/progress_provider.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/offline_status_widget.dart';
import '../widgets/theme_accessibility_mini_preview.dart';
import 'quiz/pick_topic_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _dailyGoalTarget = 20;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;

      final progress = Provider.of<ProgressProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);

      progress.token = auth.token;
      coinProvider.loadCoinsAndHints();

      progress.onLevelUp = () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => LevelUpAnimation(
            level: progress.level,
            onFinished: () {
              Navigator.pop(context);
            },
          ),
        );
      };

      progress.loadProgress();
      progress.loadTopics();
    });
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
        Navigator.pushNamed(
          context,
          "/quiz",
          arguments: _resolveQuizTopicId(progress),
        );
        return;
      case 2:
        Navigator.pushNamed(context, "/leaderboard");
        return;
      case 3:
        Navigator.pushNamed(context, "/profile");
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final progress = Provider.of<ProgressProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final username = auth.username?.trim();
    final recommendedTopic = _findRecommendedTopic(progress);
    final dailyDone = progress.totalAttempts % _dailyGoalTarget;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: OfflineStatusWidget(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      t.hello(
                        username?.isNotEmpty == true
                            ? username!
                            : t.fallbackStudent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, "/badges"),
                        icon: const Icon(Icons.workspace_premium_outlined),
                        color: colorScheme.onSurface,
                        tooltip: t.badges,
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, "/heatmap"),
                        icon: const Icon(Icons.calendar_month),
                        color: colorScheme.onSurface,
                        tooltip: t.activity,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildStatChip(
                    icon: Icons.local_fire_department,
                    value: t.streakDays(progress.streak),
                    backgroundColor: colorScheme.secondaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                  Consumer<CoinProvider>(
                    builder: (context, coinProvider, child) {
                      return _buildStatChip(
                        icon: Icons.monetization_on,
                        value: t.coins(coinProvider.coins),
                        backgroundColor: colorScheme.tertiaryContainer
                            .withValues(alpha: 0.5),
                        foregroundColor: colorScheme.onTertiaryContainer,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                t.level(progress.level),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${progress.xp} / ${progress.xpToNextLevel} XP",
                style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
              ),
              const SizedBox(height: 10),
              AnimatedXpBar(
                currentXp: progress.xp,
                maxXp: progress.xpToNextLevel,
              ),
              const SizedBox(height: 18),
              _buildContinueCard(
                title: recommendedTopic != null
                    ? t.continueLearning
                    : t.readyForNewRound,
                subtitle: recommendedTopic?.name ?? t.pickTopicAndStart,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    "/quiz",
                    arguments: _resolveQuizTopicId(progress),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: progress.topics.isEmpty
                      ? null
                      : () => _openTopicPicker(progress),
                  icon: const Icon(Icons.auto_stories),
                  label: Text(t.chooseTopic),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                t.dailyGoal(_dailyGoalTarget),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: dailyDone / _dailyGoalTarget,
                  backgroundColor: colorScheme.onSurface.withValues(
                    alpha: 0.12,
                  ),
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.todayProgress(dailyDone, _dailyGoalTarget),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
              ),
              const SizedBox(height: 14),
              ThemeAccessibilityMiniPreview(
                title: t.homeAccessibilityPreview,
                compact: true,
              ),
              const SizedBox(height: 14),
              Text(
                t.learningTopics,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: progress.topics.length,
                  itemBuilder: (context, i) {
                    final topic = progress.topics[i];
                    final locked =
                        !topic.unlocked || progress.level < topic.requiredLevel;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: locked
                            ? null
                            : () {
                                Navigator.pushNamed(
                                  context,
                                  "/quiz",
                                  arguments: topic.topicId,
                                );
                              },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: locked
                                ? colorScheme.surface.withValues(alpha: 0.55)
                                : colorScheme.primaryContainer.withValues(
                                    alpha: 0.35,
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: locked
                                  ? colorScheme.outline.withValues(alpha: 0.5)
                                  : colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                locked ? Icons.lock : Icons.play_circle_fill,
                                color: locked
                                    ? colorScheme.onSurface
                                    : colorScheme.primary,
                                size: 34,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.name,
                                      style: TextStyle(
                                        color: locked
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      locked
                                          ? t.unlockAtLevel(topic.requiredLevel)
                                          : t.readyForQuiz,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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

  Widget _buildContinueCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_fill,
              color: colorScheme.onPrimary,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
