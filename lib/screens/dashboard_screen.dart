import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_i18n.dart';
import '../models/topic_item.dart';
import '../navigation/app_routes.dart';
import '../navigation/navigation_extensions.dart';
import '../state/auth_provider.dart';
import '../state/badge_provider.dart';
import '../state/coin_provider.dart';
import '../state/leaderboard_provider.dart';
import '../state/learning_path_provider.dart';
import '../state/progress_provider.dart';
import '../state/quiz_provider.dart';
import '../state/streak_freeze_provider.dart';
import '../theme/app_scale.dart';
import '../theme/theme_extensions/theme_context.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../widgets/ui/app_card.dart';
import '../ui/motion_scope.dart';
import '../utils/overlay_safety.dart';
import '../widgets/animated_xp_bar.dart';
import '../widgets/leaderboard_item.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/mastery_ring_indicator.dart';
import '../widgets/offline_status_widget.dart';
import '../widgets/streak_badge_presenter.dart';
import '../widgets/ui/app_section.dart';
import '../widgets/ui/state_scaffold.dart';
import 'quiz/pick_topic_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const int _dailyGoalTarget = 20;

  late Future<int> _dailyReviewCountFuture;
  late final AnimationController _refreshSpinController;

  String? _error;
  bool _isBootstrapping = true;
  bool _isRefreshingDailyReview = false;
  bool _showRefreshSuccess = false;
  Timer? _refreshSuccessTimer;

  @override
  void initState() {
    super.initState();
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addObserver(this);
    _refreshDailyReviewCount();
    _bootstrapHome();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshSpinController.dispose();
    _refreshSuccessTimer?.cancel();
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

  Future<void> _bootstrapHome() async {
    try {
      if (!mounted) return;

      final progress = Provider.of<ProgressProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final coinProvider = Provider.of<CoinProvider>(context, listen: false);
      final leaderboard = Provider.of<LeaderboardProvider>(
        context,
        listen: false,
      );

      progress.token = auth.token;
      leaderboard.onTokenUpdated(auth.token);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        coinProvider.loadCoinsAndHints();
        leaderboard.loadGlobal();
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
      if (mounted) setState(() => _isBootstrapping = false);
    }
  }

  void _retryBootstrap() {
    setState(() {
      _isBootstrapping = true;
      _error = null;
    });
    _bootstrapHome();
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
      _refreshSuccessTimer?.cancel();
      _refreshSuccessTimer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() => _showRefreshSuccess = false);
      });
    });
  }

  TopicProgress? _findRecommendedTopic(ProgressProvider progress) {
    for (final topic in progress.topics) {
      if (topic.unlocked && progress.level >= topic.requiredLevel) {
        return topic;
      }
    }
    return null;
  }

  int _resolveQuizTopicId(ProgressProvider progress) {
    final recommended = _findRecommendedTopic(progress);
    if (recommended != null) return recommended.topicId;
    if (progress.topics.isNotEmpty) return progress.topics.first.topicId;
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

  Future<void> _safeSelectionHaptic() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  String _formatDailyReviewSubtitle(int count) {
    if (count == 0) return 'Nema SRS pitanja za danas';
    final minutes = ((count * 45) / 60).round().clamp(1, 99);
    return 'Danas imas $count SRS pitanja - ~$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colors = context.colors;
    final progress = context.watch<ProgressProvider>();
    final auth = context.watch<AuthProvider>();
    final reduce =
        MotionScope.maybeOf(context)?.reduce ??
        MediaQuery.of(context).disableAnimations;
    final username = auth.username?.trim();
    final recommendedTopic = _findRecommendedTopic(progress);
    final dailyDone = progress.totalAttempts % _dailyGoalTarget;
    final hasStreakFreezeProvider =
        context.watch<StreakFreezeProvider?>() != null;

    return Scaffold(
      backgroundColor: colors.screenBackground,
      body: StateScaffold(
        isLoading: _isBootstrapping,
        isEmpty: !_isBootstrapping && _error == null && progress.topics.isEmpty,
        error: _error,
        onRetry: _retryBootstrap,
        emptyTitle: 'Nema dostupnih tema',
        emptySubtitle: 'Osvezi ekran ili pokusaj ponovo kasnije.',
        emptyIcon: Icons.auto_stories_outlined,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Pinned stats header ───────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _DashboardHeaderDelegate(
                  username: username?.isNotEmpty == true
                      ? username!
                      : t.fallbackStudent,
                  level: progress.level,
                  xp: progress.xp,
                  xpToNextLevel: progress.xpToNextLevel,
                  streak: progress.streak,
                  dailyDone: dailyDone,
                  dailyGoalTarget: _dailyGoalTarget,
                  t: t,
                  isDemoMode: auth.isDemoMode,
                  onBadgesTap: context.openBadges,
                  onHeatmapTap: context.goHeatmap,
                ),
              ),

              // ── Offline indicator ─────────────────────────────────────
              const SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topRight,
                  child: OfflineStatusWidget(),
                ),
              ),

              // ── Streak badge presenter ────────────────────────────────
              if (hasStreakFreezeProvider)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.base,
                      AppSpacing.xs,
                      AppSpacing.base,
                      0,
                    ),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: StreakBadgePresenter(),
                    ),
                  ),
                ),

              // ── Continue Learning ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  child: AppSection(
                    title: recommendedTopic != null
                        ? t.continueLearning
                        : t.readyForNewRound,
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ContinueCard(
                      title: recommendedTopic != null
                          ? t.continueLearning
                          : t.readyForNewRound,
                      subtitle: recommendedTopic?.name ?? t.pickTopicAndStart,
                      onTap: () => context.pushQuiz(
                        topicId: _resolveQuizTopicId(progress),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Learning path banner ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    0,
                    AppSpacing.base,
                    AppSpacing.md,
                  ),
                  child: const _LearningPathBanner(),
                ),
              ),

              // ── Daily missions (horizontal) ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  child: _DailyMissionsSection(
                    progress: progress,
                    dailyDone: dailyDone,
                    dailyGoalTarget: _dailyGoalTarget,
                    t: t,
                    reduce: reduce,
                  ),
                ),
              ),

              // ── Quick Practice (3 topic cards) ────────────────────────
              if (progress.topics.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    child: _QuickPracticeSection(
                      topics: progress.topics,
                      level: progress.level,
                      onTopicTap: (id) => context.pushQuiz(topicId: id),
                      onAllTopics: () => _openTopicPicker(progress),
                      t: t,
                    ),
                  ),
                ),

              // ── Daily Review ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  child: AppSection(
                    title: 'Daily Review',
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: FutureBuilder<int>(
                      future: _dailyReviewCountFuture,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        final isLoading =
                            snapshot.connectionState ==
                                ConnectionState.waiting ||
                            _isRefreshingDailyReview;
                        final subtitle = isLoading
                            ? 'Ucitavam dnevni review...'
                            : _formatDailyReviewSubtitle(count);
                        final isEnabled = !isLoading && count > 0;
                        return _DailyReviewCard(
                          title: 'Daily Review',
                          subtitle: subtitle,
                          enabled: isEnabled,
                          subtitleLoading: isLoading,
                          refreshSpinController: _refreshSpinController,
                          showRefreshSuccess: _showRefreshSuccess,
                          isRefreshing: _isRefreshingDailyReview,
                          onTap: isEnabled
                              ? () async {
                                  await _safeSelectionHaptic();
                                  if (!context.mounted) return;
                                  await const DailyReviewRoute().push<void>(
                                    context,
                                  );
                                  if (!context.mounted) return;
                                  _refreshDailyReviewCount();
                                }
                              : null,
                          onDisabledTap: !isEnabled
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nema pitanja za danas.'),
                                    ),
                                  );
                                }
                              : null,
                          onRefresh: _isRefreshingDailyReview
                              ? null
                              : _refreshDailyReviewCount,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Leaderboard Preview ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  child: _LeaderboardPreviewSection(
                    onSeeAll: context.openLeaderboard,
                    t: t,
                  ),
                ),
              ),

              // ── Achievements ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                  child: _AchievementsSection(
                    onSeeAll: context.openBadges,
                    t: t,
                  ),
                ),
              ),

              // ── Learning Progress Grid ────────────────────────────────
              if (progress.topics.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    child: _LearningProgressGrid(
                      topics: progress.topics,
                      level: progress.level,
                      accuracy: progress.accuracy,
                      t: t,
                      reduce: reduce,
                    ),
                  ),
                ),

              // ── Bottom padding ────────────────────────────────────────
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets / delegates ──────────────────────────────────────────

// ── Pinned header delegate ────────────────────────────────────────────────────

class _DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String username;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int streak;
  final int dailyDone;
  final int dailyGoalTarget;
  final AppI18n t;
  final bool isDemoMode;
  final VoidCallback onBadgesTap;
  final VoidCallback onHeatmapTap;

  const _DashboardHeaderDelegate({
    required this.username,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.streak,
    required this.dailyDone,
    required this.dailyGoalTarget,
    required this.t,
    required this.isDemoMode,
    required this.onBadgesTap,
    required this.onHeatmapTap,
  });

  // Extent is computed from AppScale so it adapts to screen width.
  static double get _extent => AppScale.s(176);

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  bool shouldRebuild(_DashboardHeaderDelegate o) =>
      username != o.username ||
      level != o.level ||
      xp != o.xp ||
      streak != o.streak ||
      dailyDone != o.dailyDone ||
      isDemoMode != o.isDemoMode;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = context.colors;

    return Material(
      color: colors.screenBackground,
      elevation: overlapsContent ? 2 : 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Demo mode banner
            if (isDemoMode)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppScale.radius(6)),
                    border: Border.all(color: colorScheme.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onPrimaryContainer,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Demo režim',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: AppScale.font(11, min: 10, max: 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Greeting row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t.hello(username),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: onBadgesTap,
                      icon: Icon(
                        Icons.workspace_premium_outlined,
                        size: AppScale.icon(24, min: 22, max: 30),
                      ),
                      color: colors.textPrimary,
                      tooltip: context.safeTooltip(t.badges),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      onPressed: onHeatmapTap,
                      icon: Icon(
                        Icons.calendar_month,
                        size: AppScale.icon(24, min: 22, max: 30),
                      ),
                      color: colors.textPrimary,
                      tooltip: context.safeTooltip(t.activity),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),

            // Stat chips
            Consumer<CoinProvider>(
              builder: (context, coins, _) => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _StatChip(
                    icon: Icons.local_fire_department,
                    label: t.streakDays(streak),
                    backgroundColor: colorScheme.secondaryContainer.withValues(
                      alpha: 0.55,
                    ),
                    foregroundColor: colorScheme.onSecondaryContainer,
                  ),
                  _StatChip(
                    icon: Icons.monetization_on,
                    label: t.coins(coins.coins),
                    backgroundColor: colorScheme.tertiaryContainer.withValues(
                      alpha: 0.55,
                    ),
                    foregroundColor: colorScheme.onTertiaryContainer,
                  ),
                  _StatChip(
                    icon: Icons.flag_circle_outlined,
                    label: t.dailyGoalShort(dailyDone, dailyGoalTarget),
                    backgroundColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.55,
                    ),
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xs),

            // XP bar
            Row(
              children: [
                Text(
                  t.level(level),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$xp / $xpToNextLevel XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs / 2),
            AnimatedXpBar(currentXp: xp, maxXp: xpToNextLevel),
          ],
        ),
      ),
    );
  }
}

// ── Daily Missions ────────────────────────────────────────────────────────────

class _DailyMission {
  final IconData icon;
  final String title;
  final double progress;
  final int xpReward;

  const _DailyMission({
    required this.icon,
    required this.title,
    required this.progress,
    required this.xpReward,
  });
}

class _DailyMissionsSection extends StatelessWidget {
  final ProgressProvider progress;
  final int dailyDone;
  final int dailyGoalTarget;
  final AppI18n t;
  final bool reduce;

  const _DailyMissionsSection({
    required this.progress,
    required this.dailyDone,
    required this.dailyGoalTarget,
    required this.t,
    required this.reduce,
  });

  List<_DailyMission> _buildMissions() {
    final goalProgress = (dailyDone / dailyGoalTarget).clamp(0.0, 1.0);
    final streakProgress = progress.isStreakDoneToday ? 1.0 : goalProgress;
    final accuracyProgress = (progress.accuracy / 100.0).clamp(0.0, 1.0);

    return [
      _DailyMission(
        icon: Icons.auto_awesome,
        title: 'Daily Review',
        progress: streakProgress,
        xpReward: 30,
      ),
      _DailyMission(
        icon: Icons.auto_stories,
        title: t.missionTopics,
        progress: goalProgress,
        xpReward: 50,
      ),
      _DailyMission(
        icon: Icons.emoji_events,
        title: t.masteryLabel,
        progress: accuracyProgress,
        xpReward: 20,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final missions = _buildMissions();
    final spacing = context.spacing;

    return AppSection(
      title: 'Dnevne misije',
      padding: EdgeInsets.only(bottom: spacing.m),
      child: RepaintBoundary(
        child: SizedBox(
          height: AppScale.s(112),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: missions.length,
            separatorBuilder: (_, index) => SizedBox(width: spacing.m),
            itemBuilder: (context, i) =>
                _DailyMissionCard(mission: missions[i], reduce: reduce),
          ),
        ),
      ),
    );
  }
}

class _DailyMissionCard extends StatelessWidget {
  final _DailyMission mission;
  final bool reduce;

  const _DailyMissionCard({required this.mission, required this.reduce});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radius = context.radius;
    final theme = Theme.of(context);
    final isDone = mission.progress >= 1.0;

    return Semantics(
      label:
          '${mission.title}, ${(mission.progress * 100).toInt()}% complete, +${mission.xpReward} XP',
      child: Container(
        width: AppScale.s(140),
        padding: EdgeInsets.all(spacing.m),
        decoration: BoxDecoration(
          color: isDone
              ? colors.masteryStrong.withValues(alpha: 0.12)
              : colors.cardBackground,
          borderRadius: BorderRadius.circular(radius.card),
          border: Border.all(
            color: isDone ? colors.masteryStrong : colors.border,
            width: isDone ? 1.5 : 1,
          ),
          boxShadow: context.shadows.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDone ? Icons.check_circle : mission.icon,
                  color: isDone ? colors.masteryStrong : colors.textSecondary,
                  size: AppScale.icon(20, min: 18, max: 26),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.masteryStrong.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(radius.pill),
                  ),
                  child: Text(
                    '+${mission.xpReward} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.masteryStrong,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.s),
            Text(
              mission.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(radius.pill),
              child: LinearProgressIndicator(
                value: mission.progress,
                backgroundColor: colors.border,
                color: isDone ? colors.masteryStrong : colors.textSecondary,
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Practice ────────────────────────────────────────────────────────────

class _QuickPracticeSection extends StatelessWidget {
  final List<TopicProgress> topics;
  final int level;
  final void Function(int topicId) onTopicTap;
  final VoidCallback onAllTopics;
  final AppI18n t;

  const _QuickPracticeSection({
    required this.topics,
    required this.level,
    required this.onTopicTap,
    required this.onAllTopics,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final displayTopics = topics.take(3).toList();
    final spacing = context.spacing;

    return AppSection(
      title: t.missionTopics,
      trailing: TextButton.icon(
        onPressed: onAllTopics,
        icon: const Icon(Icons.auto_stories),
        label: Text(t.allTopics),
      ),
      padding: EdgeInsets.only(bottom: spacing.m),
      child: Column(
        children: displayTopics.map((topic) {
          final locked = !topic.unlocked || level < topic.requiredLevel;
          return Padding(
            padding: EdgeInsets.only(bottom: spacing.s),
            child: _TopicCard(
              topic: topic,
              locked: locked,
              onTap: locked ? null : () => onTopicTap(topic.topicId),
              t: t,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final TopicProgress topic;
  final bool locked;
  final VoidCallback? onTap;
  final AppI18n t;

  const _TopicCard({
    required this.topic,
    required this.locked,
    this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radius = context.radius;
    final theme = Theme.of(context);

    return Semantics(
      label:
          '${topic.name}, ${locked ? t.unlockAtLevel(topic.requiredLevel) : t.readyToPlay}',
      button: !locked,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.symmetric(
          horizontal: spacing.m,
          vertical: spacing.m,
        ),
        backgroundColor: locked
            ? colors.cardBackground.withValues(alpha: 0.6)
            : colors.cardBackground,
        child: Row(
          children: [
            Container(
              width: AppScale.s(44),
              height: AppScale.s(44),
              decoration: BoxDecoration(
                color: (locked ? colors.border : colors.masteryStrong)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radius.medium),
              ),
              child: Icon(
                locked ? Icons.lock_outline : Icons.auto_stories,
                color: locked ? colors.textSecondary : colors.masteryStrong,
                size: AppScale.icon(22, min: 20, max: 28),
              ),
            ),
            SizedBox(width: spacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: locked ? colors.textSecondary : colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    locked
                        ? t.unlockAtLevel(topic.requiredLevel)
                        : t.readyToPlay,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.s),
            if (!locked)
              FilledButton.tonal(onPressed: onTap, child: Text(t.play))
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

// ── Leaderboard Preview ───────────────────────────────────────────────────────

class _LeaderboardPreviewSection extends StatelessWidget {
  final VoidCallback onSeeAll;
  final AppI18n t;

  const _LeaderboardPreviewSection({required this.onSeeAll, required this.t});

  @override
  Widget build(BuildContext context) {
    final leaderboard = context.watch<LeaderboardProvider>();
    final items = leaderboard
        .itemsFor(LeaderboardScope.global)
        .take(3)
        .toList();
    final me = leaderboard.meFor(LeaderboardScope.global);
    final colors = context.colors;
    final spacing = context.spacing;
    final theme = Theme.of(context);

    return AppSection(
      title: 'Rang lista',
      trailing: TextButton(onPressed: onSeeAll, child: const Text('Sve')),
      padding: EdgeInsets.only(bottom: spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My rank chip
          if (me != null) ...[
            Semantics(
              label: 'Moj rang: #${me.rank}, Top ${me.percentile}%',
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.m,
                  vertical: spacing.s,
                ),
                decoration: BoxDecoration(
                  color: context.leaderboardTheme.currentUserHighlight,
                  borderRadius: BorderRadius.circular(context.radius.medium),
                  border: Border.all(color: colors.leaderboardGold),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: colors.leaderboardGold,
                      size: AppScale.icon(18, min: 16, max: 24),
                    ),
                    SizedBox(width: spacing.s),
                    Text(
                      'Moj rang: #${me.rank}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: spacing.m),
                    Text(
                      'Top ${me.percentile}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: spacing.s),
          ],

          // Top entries
          if (!leaderboard.hasLoaded(LeaderboardScope.global))
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.m),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.m),
              child: Center(
                child: Text(
                  'Nema podataka',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...items.map(
              (item) => RepaintBoundary(
                child: LeaderboardItemWidget(
                  item: item,
                  isCurrentUser: me != null && item.rank == me.rank,
                ),
              ),
            ),

          SizedBox(height: spacing.s),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSeeAll,
              icon: const Icon(Icons.leaderboard),
              label: const Text('Pogledaj celu rang listu'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievements ──────────────────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  final VoidCallback onSeeAll;
  final AppI18n t;

  const _AchievementsSection({required this.onSeeAll, required this.t});

  @override
  Widget build(BuildContext context) {
    final badges = context.watch<BadgeProvider>().badges;
    final spacing = context.spacing;

    return AppSection(
      title: t.badges,
      trailing: TextButton(onPressed: onSeeAll, child: const Text('Sve')),
      padding: EdgeInsets.only(bottom: spacing.m),
      child: RepaintBoundary(
        child: SizedBox(
          height: AppScale.s(92),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, index) => SizedBox(width: spacing.s),
            itemBuilder: (_, i) => _BadgeChip(badge: badges[i]),
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final AppBadge badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radius;
    final theme = Theme.of(context);

    return Semantics(
      label:
          '${badge.name}, ${badge.unlocked ? "unlocked" : "${(badge.progress * 100).toInt()}% progress"}',
      child: Opacity(
        opacity: badge.unlocked ? 1.0 : 0.55,
        child: Container(
          width: AppScale.s(72),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: badge.unlocked
                ? colors.masteryStrong.withValues(alpha: 0.12)
                : colors.cardBackground,
            borderRadius: BorderRadius.circular(radius.medium),
            border: Border.all(
              color: badge.unlocked ? colors.masteryStrong : colors.border,
              width: badge.unlocked ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.icon,
                style: TextStyle(fontSize: AppScale.font(26, min: 22, max: 34)),
              ),
              const SizedBox(height: 4),
              Text(
                badge.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badge.unlocked
                      ? colors.textPrimary
                      : colors.textSecondary,
                  fontWeight: badge.unlocked
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Learning Progress Grid ────────────────────────────────────────────────────

class _LearningProgressGrid extends StatelessWidget {
  final List<TopicProgress> topics;
  final int level;
  final double accuracy;
  final AppI18n t;
  final bool reduce;

  const _LearningProgressGrid({
    required this.topics,
    required this.level,
    required this.accuracy,
    required this.t,
    required this.reduce,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final radius = context.radius;
    final theme = Theme.of(context);
    final masteryValue = (accuracy / 100.0).clamp(0.0, 1.0);

    return AppSection(
      title: 'Napredak učenja',
      padding: EdgeInsets.only(bottom: spacing.m),
      child: RepaintBoundary(
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: spacing.s,
            crossAxisSpacing: spacing.s,
            childAspectRatio: 0.9,
          ),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            final locked = !topic.unlocked || level < topic.requiredLevel;
            final progress = locked ? 0.0 : masteryValue;

            return Semantics(
              label:
                  '${topic.name}, ${locked ? t.unlockAtLevel(topic.requiredLevel) : "${(progress * 100).toInt()}% ${t.masteryLabel}"}',
              child: Container(
                padding: EdgeInsets.all(spacing.s),
                decoration: BoxDecoration(
                  color: locked
                      ? colors.cardBackground.withValues(alpha: 0.5)
                      : colors.cardBackground,
                  borderRadius: BorderRadius.circular(radius.card),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MasteryRingIndicator(
                      progress: progress,
                      size: AppScale.s(52),
                      strokeWidth: AppScale.s(5),
                      progressColor: locked
                          ? colors.border
                          : colors.masteryStrong,
                      trackColor: colors.border,
                      animate: !reduce,
                      child: Icon(
                        locked ? Icons.lock_outline : Icons.auto_stories,
                        size: AppScale.icon(18, min: 16, max: 24),
                        color: locked
                            ? colors.textSecondary
                            : colors.masteryStrong,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      topic.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: locked
                            ? colors.textSecondary
                            : colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Existing sub-widgets (kept) ───────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppScale.radius(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: foregroundColor,
            size: AppScale.icon(18, min: 16, max: 24),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: AppScale.font(13, min: 12, max: 17),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppScale.radius(18)),
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
          ),
          borderRadius: BorderRadius.circular(AppScale.radius(18)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: AppScale.s(16),
              offset: Offset(0, AppScale.s(6)),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppScale.s(18),
          vertical: AppScale.s(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_fill,
              color: colorScheme.onPrimary,
              size: AppScale.icon(30, min: 26, max: 40),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: AppScale.font(18, min: 16, max: 24),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: AppScale.font(13, min: 12, max: 18),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward,
              color: colorScheme.onPrimary,
              size: AppScale.icon(22, min: 20, max: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyReviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final bool subtitleLoading;
  final bool isRefreshing;
  final bool showRefreshSuccess;
  final AnimationController refreshSpinController;
  final VoidCallback? onTap;
  final VoidCallback? onDisabledTap;
  final VoidCallback? onRefresh;

  const _DailyReviewCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.subtitleLoading,
    required this.isRefreshing,
    required this.showRefreshSuccess,
    required this.refreshSpinController,
    this.onTap,
    this.onDisabledTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$title, $subtitle',
      button: true,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: InkWell(
          onTap: enabled ? onTap : onDisabledTap,
          borderRadius: BorderRadius.circular(AppScale.radius(18)),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppScale.radius(18)),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.7),
                width: AppScale.s(1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withValues(alpha: 0.2),
                  blurRadius: AppScale.s(14),
                  offset: Offset(0, AppScale.s(6)),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppScale.s(14),
            ),
            child: Row(
              children: [
                Container(
                  width: AppScale.s(44),
                  height: AppScale.s(44),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondary.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: colorScheme.secondary,
                    size: AppScale.icon(24, min: 22, max: 32),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: AppScale.font(16, min: 14, max: 22),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(
                            alpha: enabled ? 0.7 : 0.45,
                          ),
                          fontSize: AppScale.font(13, min: 12, max: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRefresh != null)
                  RotationTransition(
                    turns: refreshSpinController,
                    child: IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      iconSize: AppScale.icon(20, min: 18, max: 26),
                      color: colorScheme.secondary,
                      tooltip: 'Refresh',
                    ),
                  )
                else if (showRefreshSuccess)
                  Icon(
                    Icons.check_circle_outline,
                    color: colorScheme.secondary,
                    size: AppScale.icon(20, min: 18, max: 26),
                  ),
              ],
            ),
          ),
        ),
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
    final provider = context.watch<LearningPathProvider?>();
    final recommended = provider?.recommended;
    final String title = recommended != null
        ? recommended.topicName
        : 'Start your path';
    final String subtitle = recommended != null
        ? (recommended.recommendationReason ?? 'Continue where you left off')
        : 'Build skills step by step';
    return GestureDetector(
      onTap: () => context.goLearnMap(focusNodeId: recommended?.id),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppScale.s(4)),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppScale.s(14),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer, cs.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppScale.radius(16)),
          border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppScale.s(10)),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_rounded,
                color: cs.primary,
                size: AppScale.icon(24, min: 22, max: 32),
              ),
            ),
            SizedBox(width: AppScale.s(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Learning Map',
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: cs.primary,
              size: AppScale.icon(22, min: 20, max: 28),
            ),
          ],
        ),
      ),
    );
  }
}
