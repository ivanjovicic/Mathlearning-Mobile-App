import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mathlearning/widgets/animated_xp_bar.dart';
import 'package:provider/provider.dart';

import '../l10n/app_i18n.dart';
import '../models/topic_item.dart';
import '../state/auth_provider.dart';
import '../state/coin_provider.dart';
import '../state/progress_provider.dart';
import '../state/quiz_provider.dart';
import '../theme/astrax_theme.dart';
import '../utils/overlay_safety.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/offline_status_widget.dart';
import '../widgets/streak_badge_presenter.dart';
import '../widgets/theme_accessibility_mini_preview.dart';
import '../widgets/astrax_bottom_nav.dart';
import '../widgets/astrax_xp_bar.dart';
import 'quiz/pick_topic_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const int _dailyGoalTarget = 20;
  late Future<int> _dailyReviewCountFuture;
  late final AnimationController _refreshSpinController;
  bool _isRefreshingDailyReview = false;
  bool _showRefreshSuccess = false;

  @override
  void initState() {
    super.initState();
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addObserver(this);
    _refreshDailyReviewCount();
    Future.microtask(() async {
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

      await progress.loadProgress();
      await progress.rollDailyStreakIfNeeded();
      if (!mounted) return;
      progress.loadTopics();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshSpinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDailyReviewCount();
      Future.microtask(() async {
        if (!mounted) return;
        final progress = Provider.of<ProgressProvider>(context, listen: false);
        await progress.rollDailyStreakIfNeeded();
      });
    }
  }

  void _refreshDailyReviewCount() {
    if (!mounted) return;
    setState(() {
      _isRefreshingDailyReview = true;
      _dailyReviewCountFuture = Provider.of<QuizProvider>(
        context,
        listen: false,
      ).getDailySrsCount();
    });
    _refreshSpinController
      ..reset()
      ..repeat();
    _dailyReviewCountFuture.whenComplete(() {
      if (!mounted) return;
      setState(() => _isRefreshingDailyReview = false);
      _refreshSpinController
        ..stop()
        ..reset();
      setState(() => _showRefreshSuccess = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => _showRefreshSuccess = false);
      });
    });
  }

  String _formatDailyReviewSubtitle(int count) {
    if (count == 0) {
      return "Nema SRS pitanja za danas";
    }

    final totalSeconds = (count * 45);
    final minutes = (totalSeconds / 60).round().clamp(1, 99);
    return "Danas imas $count SRS pitanja - ~$minutes min";
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final username = auth.username?.trim();
    final recommendedTopic = _findRecommendedTopic(progress);
    final dailyDone = progress.totalAttempts % _dailyGoalTarget;

    return Scaffold(
      backgroundColor: AstraXTheme.bg,
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
                        tooltip: context.safeTooltip(t.badges),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, "/heatmap"),
                        icon: const Icon(Icons.calendar_month),
                        color: colorScheme.onSurface,
                        tooltip: context.safeTooltip(t.activity),
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
              const StreakBadgePresenter(),
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              AstraXPBar(
                progress: progress.xpToNextLevel == 0
                    ? 0
                    : progress.xp / progress.xpToNextLevel,
              ),
              const SizedBox(height: 6),
              Text(
                t.nextLevelHint,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
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
              const SizedBox(height: 10),
              FutureBuilder<int>(
                future: _dailyReviewCountFuture,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting ||
                      _isRefreshingDailyReview;
                  final subtitle = isLoading
                      ? "Ucitavam dnevni review..."
                      : _formatDailyReviewSubtitle(count);
                  final isEnabled = !isLoading && count > 0;

                  final card = _buildDailyReviewCard(
                    title: "Daily Review",
                    subtitle: subtitle,
                    enabled: isEnabled,
                    onTap: isEnabled
                        ? () async {
                            HapticFeedback.selectionClick();
                            await Navigator.pushNamed(context, "/daily-review");
                            if (!mounted) return;
                            _refreshDailyReviewCount();
                          }
                        : null,
                    onDisabledTap: !isEnabled
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Nema pitanja za danas."),
                              ),
                            );
                          }
                        : null,
                    onRefresh: _isRefreshingDailyReview
                        ? null
                        : _refreshDailyReviewCount,
                    subtitleLoading: isLoading,
                  );

                  if (reduceMotion) {
                    return card;
                  }

                  return card
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .scale(duration: 300.ms, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(
                        duration: 1200.ms,
                        color: colorScheme.secondary.withValues(alpha: 0.6),
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
      bottomNavigationBar: AstraBottomNav(
        currentIndex: 0,
        onChanged: (index) => _onBottomNavTap(index, progress),
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

  Widget _buildDailyReviewCard({
    required String title,
    required String subtitle,
    required bool enabled,
    VoidCallback? onTap,
    VoidCallback? onDisabledTap,
    VoidCallback? onRefresh,
    bool subtitleLoading = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: "$title, $subtitle",
      button: true,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: InkWell(
          onTap: enabled ? onTap : onDisabledTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondary.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: enabled ? 0.7 : 0.45,
                              ),
                              fontSize: 13,
                            ),
                          )
                          .animate(
                            target: subtitleLoading && !reduceMotion ? 1 : 0,
                          )
                          .shimmer(
                            duration: 900.ms,
                            color: colorScheme.secondary.withValues(alpha: 0.6),
                          ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (onRefresh != null)
                  Semantics(
                    button: true,
                    label: "Osvezi",
                    child: InkResponse(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onRefresh();
                      },
                      radius: 22,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.secondary.withValues(alpha: 0.12),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _showRefreshSuccess
                              ? Icon(
                                  Icons.check,
                                  key: const ValueKey('refresh_check'),
                                  size: 18,
                                  color: colorScheme.secondary,
                                ).animate().scale(
                                  duration: 200.ms,
                                  curve: Curves.easeOutBack,
                                )
                              : RotationTransition(
                                  key: const ValueKey('refresh_spin'),
                                  turns: _refreshSpinController,
                                  child:
                                      Icon(
                                            Icons.refresh,
                                            size: 18,
                                            color: colorScheme.secondary,
                                          )
                                          .animate(
                                            target:
                                                _isRefreshingDailyReview &&
                                                    !reduceMotion
                                                ? 1
                                                : 0,
                                          )
                                          .scale(
                                            begin: const Offset(1.0, 1.0),
                                            end: const Offset(1.15, 1.15),
                                            duration: 500.ms,
                                            curve: Curves.easeInOut,
                                          )
                                          .then()
                                          .scale(
                                            begin: const Offset(1.15, 1.15),
                                            end: const Offset(1.0, 1.0),
                                            duration: 500.ms,
                                            curve: Curves.easeInOut,
                                          ),
                                ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: colorScheme.onSurface),
              ],
            ),
          ),
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
