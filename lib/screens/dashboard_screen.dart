import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_i18n.dart';
import '../models/topic_item.dart';
import '../state/auth_provider.dart';
import '../state/coin_provider.dart';
import '../state/learning_path_provider.dart';
import '../state/progress_provider.dart';
import '../state/quiz_provider.dart';
import '../state/streak_freeze_provider.dart';
import '../theme/app_scale.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../utils/overlay_safety.dart';
import '../widgets/animated_xp_bar.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/offline_status_widget.dart';
import '../widgets/streak_badge_presenter.dart';
import '../widgets/theme_accessibility_mini_preview.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.noTopicsAvailable())),
      );
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
      mapped.add(TopicItem(
        id: topic.topicId,
        name: topic.name,
        accuracy: locked ? 0 : 100,
        locked: locked,
        icon: Icons.auto_stories,
        color: topicPalette[i % topicPalette.length],
      ));
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = context.watch<ProgressProvider>();
    final auth = context.watch<AuthProvider>();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final username = auth.username?.trim();
    final recommendedTopic = _findRecommendedTopic(progress);
    final dailyDone = progress.totalAttempts % _dailyGoalTarget;
    final hasStreakFreezeProvider = context.watch<StreakFreezeProvider?>() != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Offline indicator ──────────────────────────────
                      const Align(
                        alignment: Alignment.topRight,
                        child: OfflineStatusWidget(),
                      ),
                      SizedBox(height: AppSpacing.sm),

                      // ── Header row: greeting + action icons ─────────────
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
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    context.go('/profile/badges'),
                                icon: Icon(
                                  Icons.workspace_premium_outlined,
                                  size: AppScale.icon(24, min: 22, max: 30),
                                ),
                                color: colorScheme.onSurface,
                                tooltip: context.safeTooltip(t.badges),
                              ),
                              IconButton(
                                onPressed: () =>
                                    context.go('/home/heatmap'),
                                icon: Icon(
                                  Icons.calendar_month,
                                  size: AppScale.icon(24, min: 22, max: 30),
                                ),
                                color: colorScheme.onSurface,
                                tooltip: context.safeTooltip(t.activity),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),

                      // ── Demo mode banner ────────────────────────────────
                      if (auth.isDemoMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: colorScheme.primary),
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
                                'Demo režim - test podaci',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Stat chips ──────────────────────────────────────
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _StatChip(
                            icon: Icons.local_fire_department,
                            label: t.streakDays(progress.streak),
                            backgroundColor: colorScheme.secondaryContainer
                                .withValues(alpha: 0.55),
                            foregroundColor:
                                colorScheme.onSecondaryContainer,
                          ),
                          Consumer<CoinProvider>(
                            builder: (context, coins, _) => _StatChip(
                              icon: Icons.monetization_on,
                              label: t.coins(coins.coins),
                              backgroundColor: colorScheme.tertiaryContainer
                                  .withValues(alpha: 0.55),
                              foregroundColor:
                                  colorScheme.onTertiaryContainer,
                            ),
                          ),
                          _StatChip(
                            icon: Icons.flag_circle_outlined,
                            label: t.dailyGoalShort(
                                dailyDone, _dailyGoalTarget),
                            backgroundColor: colorScheme.primaryContainer
                                .withValues(alpha: 0.55),
                            foregroundColor: colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),

                      // ── Streak badge presenter ──────────────────────────
                      if (hasStreakFreezeProvider)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: StreakBadgePresenter(),
                        ),

                      // ── XP level + progress bar ─────────────────────────
                      SizedBox(height: AppSpacing.base),
                      Text(
                        t.level(progress.level),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '${progress.xp} / ${progress.xpToNextLevel} XP',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      AnimatedXpBar(
                        currentXp: progress.xp,
                        maxXp: progress.xpToNextLevel,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        t.nextLevelHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: AppSpacing.base),

                      // ── Accessibility preview ───────────────────────────
                      ThemeAccessibilityMiniPreview(
                        title: t.homeAccessibilityPreview,
                        compact: true,
                      ),
                      SizedBox(height: AppSpacing.base),

                      // ── Continue learning CTA ───────────────────────────
                      AppSection(
                        title: recommendedTopic != null
                            ? t.continueLearning
                            : t.readyForNewRound,
                        padding:
                            EdgeInsets.only(bottom: AppSpacing.base),
                        child: _ContinueCard(
                          title: recommendedTopic != null
                              ? t.continueLearning
                              : t.readyForNewRound,
                          subtitle: recommendedTopic?.name ??
                              t.pickTopicAndStart,
                          onTap: () => context.push(
                            '/quiz',
                            extra: _resolveQuizTopicId(progress),
                          ),
                        ),
                      ),

                      // ── Learning path banner ────────────────────────────
                      const _LearningPathBanner(),
                      SizedBox(height: AppSpacing.md),

                      // ── Daily review card ───────────────────────────────
                      AppSection(
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

                            final card = _DailyReviewCard(
                              title: 'Daily Review',
                              subtitle: subtitle,
                              enabled: isEnabled,
                              subtitleLoading: isLoading,
                              refreshSpinController:
                                  _refreshSpinController,
                              showRefreshSuccess: _showRefreshSuccess,
                              isRefreshing: _isRefreshingDailyReview,
                              onTap: isEnabled
                                  ? () async {
                                      final router =
                                          GoRouter.of(context);
                                      await _safeSelectionHaptic();
                                      await router.push<void>(
                                          '/home/daily-review');
                                      if (!mounted) return;
                                      _refreshDailyReviewCount();
                                    }
                                  : null,
                              onDisabledTap: !isEnabled
                                  ? () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Nema pitanja za danas.'),
                                      ));
                                    }
                                  : null,
                              onRefresh: _isRefreshingDailyReview
                                  ? null
                                  : _refreshDailyReviewCount,
                            );

                            if (reduceMotion) return card;

                            return card
                                .animate()
                                .fadeIn(duration: 250.ms)
                                .scale(
                                    duration: 300.ms,
                                    curve: Curves.easeOutBack)
                                .then()
                                .shimmer(
                                  duration: 1200.ms,
                                  color: colorScheme.secondary
                                      .withValues(alpha: 0.6),
                                );
                          },
                        ),
                      ),

                      // ── Topic picker button ─────────────────────────────
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
                      SizedBox(height: AppSpacing.md),

                      // ── Topics list ─────────────────────────────────────
                      AppSection(
                        title: t.missionTopics,
                        trailing: TextButton.icon(
                          onPressed: progress.topics.isEmpty
                              ? null
                              : () => _openTopicPicker(progress),
                          icon: const Icon(Icons.auto_stories),
                          label: Text(t.allTopics),
                        ),
                        padding:
                            EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Column(
                          children: progress.topics.map((topic) {
                            final locked = !topic.unlocked ||
                                progress.level < topic.requiredLevel;
                            return Card(
                              margin: EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              child: ListTile(
                                leading: Icon(
                                  locked
                                      ? Icons.lock_outline
                                      : Icons.play_circle_fill,
                                  color: locked
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.primary,
                                ),
                                title: Text(
                                  topic.name,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  locked
                                      ? t.unlockAtLevel(
                                          topic.requiredLevel)
                                      : t.readyToPlay,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                trailing: FilledButton.tonal(
                                  onPressed: locked
                                      ? null
                                      : () => context.push(
                                            '/quiz',
                                            extra: topic.topicId,
                                          ),
                                  child: Text(t.play),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      SizedBox(height: AppSpacing.sectionSpacing),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────────

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
          Icon(icon, color: foregroundColor, size: AppScale.icon(18, min: 16, max: 24)),
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
    final String title =
        recommended != null ? recommended.topicName : 'Start your path';
    final String subtitle = recommended != null
        ? (recommended.recommendationReason ?? 'Continue where you left off')
        : 'Build skills step by step';
    final String route = recommended != null
        ? '/learn?focus=${recommended.id}'
        : '/learn';

    return GestureDetector(
      onTap: () => context.go(route),
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
