import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/adaptive_practice/screens/adaptive_practice_screen.dart'
    as adaptive_practice;
import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/daily_reward.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/features/learning_map/models/practice_recommendation.dart';
import 'package:mathlearning/features/learning_map/models/skill_node_state.dart';
import 'package:mathlearning/navigation/navigation_extensions.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_run_card.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_chest_reward_sheet.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_reward_chest.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_missions_carousel.dart';
import 'package:mathlearning/features/learning_map/widgets/learning_map_skeleton.dart';
import 'package:mathlearning/features/learning_map/widgets/path_progress_card.dart';
import 'package:mathlearning/features/learning_map/widgets/quest_progress_list.dart';
import 'package:mathlearning/features/learning_map/widgets/skill_graph_view.dart';
import 'package:mathlearning/features/learning_map/widgets/streak_card.dart';
import 'package:mathlearning/features/learning_map/widgets/xp_level_chip.dart';
import 'package:mathlearning/services/connectivity_service.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/avatar_provider.dart';
import 'package:mathlearning/state/coin_provider.dart';
import 'package:mathlearning/state/cosmetic_target_provider.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/streak_freeze_provider.dart';
import 'package:mathlearning/state/weekly_featured_provider.dart';
import 'package:mathlearning/state/season_provider.dart';
import 'package:mathlearning/widgets/weekly_featured_banner.dart';

class LearningMapScreen extends StatefulWidget {
  const LearningMapScreen({super.key, required this.userId, this.focusNodeId});

  final String userId;
  final String? focusNodeId;

  @override
  State<LearningMapScreen> createState() => _LearningMapScreenState();
}

class _LearningMapScreenState extends State<LearningMapScreen> {
  bool _initialized = false;
  bool _dailyRunInitialized = false;
  final ScrollController _pageScrollController = ScrollController();
  final GlobalKey _xpHudTargetKey = GlobalKey(
    debugLabel: 'learning_map_xp_hud',
  );
  final GlobalKey _coinHudTargetKey = GlobalKey(
    debugLabel: 'learning_map_coin_hud',
  );
  final GlobalKey _targetChaseCardKey = GlobalKey(
    debugLabel: 'learning_map_target_chase_card',
  );
  MapCompletionFeedback? _mapCompletionFeedback;
  bool _captureScheduled = false;
  bool _mapRevealScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<LearningMapProvider>().loadAll(widget.userId);
      });
    }
    if (!_dailyRunInitialized) {
      _dailyRunInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<DailyRunProvider>().load(widget.userId);
      });
    }
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningMapProvider>();
    final path = provider.path;
    final recommendedNode = provider.recommendedNode;
    final auth = context.watch<AuthProvider>();
    final progress = context.watch<ProgressProvider>();
    final dailyRun = context.watch<DailyRunProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = ConnectivityService.instance.isOnline;
    final dailyRewardState = provider.isDailyRewardOpenedToday
        ? DailyRewardChestState.opened
        : progress.isStreakDoneToday
        ? DailyRewardChestState.ready
        : DailyRewardChestState.locked;

    _maybeCaptureCompletionFeedback(provider);
    if (path != null && _mapCompletionFeedback != null) {
      _maybeRevealMapSection();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.username?.isNotEmpty == true
              ? '${auth.username}\'s Adventure Map'
              : 'Your Adventure Map',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CoinHudChip(targetKey: _coinHudTargetKey),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(widget.userId),
        child: Builder(
          builder: (context) {
            if (provider.loading && path == null) {
              return const LearningMapSkeleton();
            }

            if (provider.error != null && path == null) {
              return _ErrorState(
                message: provider.error!,
                onRetry: () => provider.refresh(widget.userId),
              );
            }

            if (path == null || path.nodes.isEmpty) {
              return _EmptyState(
                onRetry: () => provider.refresh(widget.userId),
              );
            }

            return CustomScrollView(
              controller: _pageScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (provider.isOfflineFallback)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 16,
                            color: colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You\'re offline — showing your saved progress.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // ── XP level progress ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: const WeeklyFeaturedBanner(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: DailyRunCard(
                      isCompleted: dailyRun.isCompleted,
                      chestState: dailyRun.chestState,
                      onStart: _startDailyRun,
                      onOpenChest: _openDailyChest,
                      chaseCardKey: _targetChaseCardKey,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: XpLevelChip(
                      level: progress.level,
                      xp: progress.xp,
                      xpToNextLevel: progress.xpToNextLevel,
                      progressBarKey: _xpHudTargetKey,
                    ),
                  ),
                ),
                // ── Streak card ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: StreakCard(
                      streakDays: progress.streak,
                      practicedToday: progress.isStreakDoneToday,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: DailyRewardChest(
                      state: dailyRewardState,
                      reward: provider.todayDailyReward,
                      onOpen: dailyRewardState == DailyRewardChestState.ready
                          ? () => _openDailyReward(context)
                          : null,
                    ),
                  ),
                ),
                // ── Daily missions ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DailyMissionsCarousel(
                      missions: provider.dailyMissions,
                    ),
                  ),
                ),
                // ── Path progress ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: PathProgressCard(nodes: path.nodes),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Quests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: QuestProgressList(quests: provider.quests),
                  ),
                ),
                if (provider.recommendations.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: _RecommendationSection(
                        onPracticeTap: (topicId) {
                          final nodes = path.nodes;
                          for (final node in nodes) {
                            if (node.topicId == topicId) {
                              _openPracticeForNode(node.id);
                              return;
                            }
                          }
                          if (recommendedNode != null) {
                            _openPracticeForNode(recommendedNode.id);
                          }
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Text(
                      'Your Levels',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: SkillGraphView(
                    nodes: path.nodes,
                    focusedNodeId: widget.focusNodeId,
                    celebrationNodeId: _mapCompletionFeedback?.nodeId,
                    celebrationXp: _mapCompletionFeedback?.xpEarned,
                    autoScrollTargetNodeId: _mapCompletionFeedback == null
                        ? null
                        : recommendedNode?.id,
                    onNodeTap: (node) => _onNodeTap(context, node.id),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: recommendedNode == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _PracticeNextButton(
                key: const Key('practice_next_button'),
                node: recommendedNode,
                recommendations: provider.recommendations,
                isOnline: isOnline,
                onTap: () => _openPracticeForNode(recommendedNode.id),
              ),
            ),
    );
  }

  void _maybeCaptureCompletionFeedback(LearningMapProvider provider) {
    if (_mapCompletionFeedback != null ||
        _captureScheduled ||
        !provider.hasPendingMapCompletionFeedback) {
      return;
    }

    _captureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureScheduled = false;
      if (!mounted || _mapCompletionFeedback != null) {
        return;
      }
      final feedback = provider.takePendingMapCompletionFeedback();
      if (feedback == null) {
        return;
      }
      setState(() {
        _mapCompletionFeedback = feedback;
        _mapRevealScheduled = false;
      });

      Future<void>.delayed(const Duration(milliseconds: 2600), () {
        if (!mounted || _mapCompletionFeedback != feedback) {
          return;
        }
        setState(() => _mapCompletionFeedback = null);
      });
    });
  }

  void _maybeRevealMapSection() {
    if (_mapRevealScheduled) {
      return;
    }

    _mapRevealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_pageScrollController.hasClients) {
        return;
      }
      final position = _pageScrollController.position;
      final targetOffset = position.maxScrollExtent;
      if ((position.pixels - targetOffset).abs() < 4) {
        return;
      }
      await _pageScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onNodeTap(BuildContext context, String nodeId) {
    final provider = context.read<LearningMapProvider>();
    final node = provider.findNodeById(nodeId);
    if (node == null) {
      return;
    }

    final state = provider.getNodeState(node);
    if (state == SkillNodeState.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beat the level before this one to unlock it!'),
        ),
      );
      return;
    }

    if (!ConnectivityService.instance.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need Wi-Fi or data to play this round!'),
        ),
      );
      return;
    }

    _openPracticeForNode(node.id);
  }

  void _openPracticeForNode(String nodeId) {
    if (!ConnectivityService.instance.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need Wi-Fi or data to play this round!'),
        ),
      );
      return;
    }
    final provider = context.read<LearningMapProvider>();
    final node = provider.findNodeById(nodeId);
    if (node == null) {
      return;
    }
    final plan = provider.buildLaunchPlanForNode(node);
    context.startAdaptivePractice(plan);
  }

  Future<void> _startDailyRun() async {
    if (!ConnectivityService.instance.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need Wi-Fi or data to play this round!'),
        ),
      );
      return;
    }

    final mapProvider = context.read<LearningMapProvider>();
    final path = mapProvider.path;
    if (path == null || path.nodes.isEmpty) {
      return;
    }

    final baseNode = mapProvider.recommendedNode ?? path.nodes.first;
    final stagePlans = _buildDailyRunPlans(
      userId: widget.userId,
      path: path,
      baseNode: baseNode,
      mapProvider: mapProvider,
    );

    await context.read<DailyRunProvider>().startRun();
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => adaptive_practice.AdaptivePracticeScreen(
          plan: stagePlans.first,
          dailyRunPlans: stagePlans,
        ),
      ),
    );
  }

  List<PracticeLaunchPlan> _buildDailyRunPlans({
    required String userId,
    required AdaptiveLearningPath path,
    required SkillNode baseNode,
    required LearningMapProvider mapProvider,
  }) {
    final unlockedNodes = path.nodes.where((node) => !node.isLocked).toList();
    final warmNode = _pickNodeForDifficulty(
      unlockedNodes,
      preferred: SkillDifficulty.easy,
      fallback: baseNode,
    );
    final challengeNode = _pickNodeForDifficulty(
      unlockedNodes,
      preferred: SkillDifficulty.medium,
      fallback: baseNode,
    );
    final finalNode = _pickNodeForDifficulty(
      unlockedNodes,
      preferred: SkillDifficulty.hard,
      fallback: challengeNode,
    );

    return [
      _buildStagePlan(
        userId: userId,
        node: warmNode,
        mapProvider: mapProvider,
        difficulty: SkillDifficulty.easy,
        targetQuestions: 2,
      ),
      _buildStagePlan(
        userId: userId,
        node: challengeNode,
        mapProvider: mapProvider,
        difficulty: SkillDifficulty.medium,
        targetQuestions: 5,
      ),
      _buildStagePlan(
        userId: userId,
        node: finalNode,
        mapProvider: mapProvider,
        difficulty: SkillDifficulty.hard,
        targetQuestions: 2,
      ),
    ];
  }

  PracticeLaunchPlan _buildStagePlan({
    required String userId,
    required SkillNode node,
    required LearningMapProvider mapProvider,
    required SkillDifficulty difficulty,
    required int targetQuestions,
  }) {
    final seedPlan = mapProvider.buildLaunchPlanForNode(node);
    return PracticeLaunchPlan(
      userId: userId,
      nodeId: node.id,
      skillTitle: node.title,
      topicId: node.topicId,
      subtopicId: node.subtopicId,
      difficulty: difficulty,
      source: seedPlan.source,
      practiceId: seedPlan.practiceId,
      targetQuestions: targetQuestions,
    );
  }

  SkillNode _pickNodeForDifficulty(
    List<SkillNode> nodes, {
    required SkillDifficulty preferred,
    required SkillNode fallback,
  }) {
    for (final node in nodes) {
      if (node.recommendedDifficulty == preferred) {
        return node;
      }
    }
    return fallback;
  }

  Future<void> _openDailyReward(BuildContext context) async {
    final provider = context.read<LearningMapProvider>();
    final reward = await provider.openDailyReward();
    if (reward == null || !mounted) {
      return;
    }

    if (!mounted) return;
    switch (reward.type) {
      case DailyRewardType.xp:
        final progress = context.read<ProgressProvider>();
        progress.addXP(reward.xpAmount ?? 0);
        unawaited(progress.persistLocalProgress());
        break;
      case DailyRewardType.streakBoost:
        if (!mounted) return;
        await context.read<StreakFreezeProvider>().add(
          reward.streakBoosts ?? 1,
        );
        break;
      case DailyRewardType.cosmetic:
        break;
    }
  }

  Future<void> _openDailyChest() async {
    final dailyRun = context.read<DailyRunProvider>();
    final weeklyFeatured = _maybeRead<WeeklyFeaturedProvider>(context);
    final baseReward = await dailyRun.openChest();
    final reward = baseReward == null
        ? null
        : weeklyFeatured?.applyFeaturedBoost(baseReward) ?? baseReward;
    if (reward == null || !mounted) {
      return;
    }

    // Award season XP for completing a daily run.
    final seasonProvider = _maybeRead<SeasonProvider>(context);
    final multiplier = dailyRun.displayedXpMultiplier;
    if (seasonProvider != null) {
      await seasonProvider.awardDailyRunXp(multiplier);
    }
    final seasonXpGained = seasonProvider?.takePendingXpGain();
    final milestoneReached = seasonProvider?.takePendingMilestoneReached();

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (sheetContext) {
        void openCollectionFromSheet() {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.openAvatarCustomization();
          });
        }

        return DailyChestRewardSheet(
          reward: reward,
          xpTargetKey: _xpHudTargetKey,
          coinTargetKey: _coinHudTargetKey,
          targetCardKey: _targetChaseCardKey,
          seasonXpGained: seasonXpGained,
          milestoneReached: milestoneReached,
          onGrantCosmeticFragment: (fragmentName) {
            return context.read<AvatarProvider>().grantDailyRunFragment(
              fragmentName,
            );
          },
          onApplyTargetProgress: (result) {
            return _maybeRead<CosmeticTargetProvider>(
              context,
            )?.applyDailyRunGrant(result);
          },
          onEquipNow: (item) async {
            await context.read<AvatarProvider>().equipItem(item);
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('${item.name} equipped!')));
          },
          onViewCollection: openCollectionFromSheet,
          onApplyXp: (amount) async {
            final progress = context.read<ProgressProvider>();
            progress.addXP(amount);
            unawaited(progress.persistLocalProgress());
          },
          onApplyCoins: (amount) {
            context.read<CoinProvider>().addCoins(amount);
          },
          onContinue: () => Navigator.of(sheetContext).pop(),
        );
      },
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tomorrow\'s chest is even better 👀')),
    );
  }

  T? _maybeRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }
}

class _CoinHudChip extends StatelessWidget {
  const _CoinHudChip({required this.targetKey});

  final GlobalKey targetKey;

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<CoinProvider?>();
    if (coins == null) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: targetKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.tertiary.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            size: 16,
            color: colors.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            '${coins.coins}',
            style: textTheme.labelLarge?.copyWith(
              color: colors.onTertiaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _recommendationReasonCopy(String reason) {
  return switch (reason.toLowerCase()) {
    'low_mastery' => 'You\'re almost there — keep training!',
    'weak' => 'Time to level up your weak spot!',
    'review' => 'Quick review — lock in what you learned!',
    _ => 'You\'re on a roll — keep it up! 🔥',
  };
}

String _difficultyPromptCopy(SkillDifficulty difficulty) {
  return switch (difficulty) {
    SkillDifficulty.easy => 'Perfect starting point — jump in! 🎯',
    SkillDifficulty.medium => 'You\'ve got this — go for it! ⚡',
    SkillDifficulty.hard => 'Boss level unlocked — do you dare? 🏆',
  };
}

class _PracticeNextButton extends StatelessWidget {
  const _PracticeNextButton({
    super.key,
    required this.node,
    required this.recommendations,
    required this.isOnline,
    required this.onTap,
  });

  final SkillNode node;
  final List<PracticeRecommendation> recommendations;
  final bool isOnline;
  final VoidCallback onTap;

  String _contextLine() {
    // Try to find a matching recommendation for this node's topic.
    final rec = recommendations
        .where((r) => r.topicId == node.topicId)
        .firstOrNull;

    if (rec != null) {
      return _recommendationReasonCopy(rec.reason);
    }

    return _difficultyPromptCopy(node.recommendedDifficulty);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.primary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: InkWell(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        onTap: isOnline ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: cs.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title,
                      style: tt.titleSmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isOnline
                          ? _contextLine()
                          : 'Connect to Wi-Fi to play! 📶',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: cs.onPrimary.withValues(alpha: isOnline ? 1.0 : 0.45),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.onPracticeTap});

  final ValueChanged<int> onPracticeTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningMapProvider>();
    final items = provider.recommendations.take(3).toList(growable: false);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Up Next for You',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.topicName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _recommendationReasonCopy(item.reason),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: () => onPracticeTap(item.topicId),
                  child: const Text('Play →'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 42,
        ),
        const SizedBox(height: 14),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.route_rounded, size: 48),
        const SizedBox(height: 12),
        const Center(
          child: Text('Do a few practice rounds to build your map!'),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onRetry();
            },
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
