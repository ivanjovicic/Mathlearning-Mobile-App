import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/adaptive_practice/providers/adaptive_practice_provider.dart';
import 'package:mathlearning/features/adaptive_practice/providers/parent_dashboard_refresh_bridge.dart';
import 'package:mathlearning/features/adaptive_practice/services/practice_session_api_service.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/daily_run_burst_overlay.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/daily_run_completion_page.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/mastery_inline_meter.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/daily_run_progress_strip.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_bottom_cta.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_celebration_page.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_feedback_bar.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_options_list.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_question_card.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_rate_limit_banner.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_summary_sheet.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_top_bar.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/navigation/navigation_extensions.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';

class AdaptivePracticeScreen extends StatelessWidget {
  const AdaptivePracticeScreen({
    super.key,
    required this.plan,
    this.providerOverride,
    this.dailyRunPlans,
  });

  final PracticeLaunchPlan plan;
  final AdaptivePracticeProvider? providerOverride;
  final List<PracticeLaunchPlan>? dailyRunPlans;

  @override
  Widget build(BuildContext context) {
    final provider = providerOverride;
    if (provider != null) {
      return ChangeNotifierProvider<AdaptivePracticeProvider>.value(
        value: provider,
        child: _AdaptivePracticeView(plan: plan, dailyRunPlans: dailyRunPlans),
      );
    }

    final learningMapProvider = _maybeRead<LearningMapProvider>(context);
    if (learningMapProvider == null) {
      return const Scaffold(
        body: Center(
          child: Text('Something went wrong — go back and try again.'),
        ),
      );
    }

    final dashboardBridge = _maybeRead<ParentDashboardRefreshBridge>(context);

    return ChangeNotifierProvider<AdaptivePracticeProvider>(
      create: (_) => AdaptivePracticeProvider(
        apiService: PracticeSessionApiService(apiService: ApiService()),
        learningMapRefresher: LearningMapRefresherAdapter(learningMapProvider),
        refreshParentDashboard: dashboardBridge?.refreshAll,
      ),
      child: _AdaptivePracticeView(plan: plan, dailyRunPlans: dailyRunPlans),
    );
  }
}

class _AdaptivePracticeView extends StatefulWidget {
  const _AdaptivePracticeView({required this.plan, this.dailyRunPlans});

  final PracticeLaunchPlan plan;
  final List<PracticeLaunchPlan>? dailyRunPlans;

  @override
  State<_AdaptivePracticeView> createState() => _AdaptivePracticeViewState();
}

class _AdaptivePracticeViewState extends State<_AdaptivePracticeView> {
  bool _initialized = false;
  bool _summaryPresented = false;
  String? _selectedOption;
  int _runStageIndex = 0;
  int _runTotalXp = 0;
  int _runAnsweredQuestions = 0;
  int _runCorrectAnswers = 0;
  double _runInitialMastery = 0;
  double _runFinalMastery = 0;
  double _runMasteryDelta = 0;
  bool _runStatsInitialized = false;
  String? _handledCompletionSessionId;
  int? _latestXpGain;
  int _runCorrectStreak = 0;
  int _quickCorrectStreak = 0;
  int _mistakeCopyIndex = 0;
  bool _showRunOverlay = false;
  String? _runOverlayText;
  String? _runOverlaySubtitle;
  IconData? _runOverlayIcon;
  bool _runOverlayCompact = false;
  Timer? _runOverlayTimer;
  bool _startBeatRunning = false;

  bool get _isDailyRunMode =>
      widget.dailyRunPlans != null && widget.dailyRunPlans!.isNotEmpty;

  List<PracticeLaunchPlan> get _runPlans =>
      widget.dailyRunPlans ?? const <PracticeLaunchPlan>[];

  PracticeLaunchPlan get _currentPlan {
    if (!_isDailyRunMode) {
      return widget.plan;
    }
    final index = _runStageIndex.clamp(0, _runPlans.length - 1);
    return _runPlans[index];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final firstPlan = _isDailyRunMode ? _runPlans.first : widget.plan;
      if (_isDailyRunMode) {
        unawaited(_maybeRead<DailyRunProvider>(context)?.moveToStage(0));
        unawaited(_playStartBeatThenStart(firstPlan));
      } else {
        context.read<AdaptivePracticeProvider>().start(firstPlan);
      }
    });
  }

  @override
  void dispose() {
    _runOverlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdaptivePracticeProvider>();
    final completion = provider.completion;
    if (completion != null &&
        !_summaryPresented &&
        _handledCompletionSessionId != completion.sessionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _summaryPresented) return;
        _handleCompletion(completion);
      });
    }

    final error = provider.error;
    if (error != null &&
        provider.currentQuestion == null &&
        !provider.loading &&
        provider.sessionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Run')),
        body: _ErrorState(
          message: error,
          onRetry: () =>
              context.read<AdaptivePracticeProvider>().start(_currentPlan),
          onBack: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Selector<AdaptivePracticeProvider, double>(
                      selector: (_, value) => value.progress,
                      builder: (context, progress, _) {
                        return PracticeTopBar(
                          skillTitle: _isDailyRunMode
                              ? 'Daily Run'
                              : _currentPlan.skillTitle,
                          progress: progress,
                          onClosePressed: _confirmExit,
                        );
                      },
                    ),
                    if (_isDailyRunMode) ...[
                      const SizedBox(height: 10),
                      Selector<
                        AdaptivePracticeProvider,
                        ({int questionIndex, int targetQuestions})
                      >(
                        selector: (_, value) => (
                          questionIndex: value.questionIndex,
                          targetQuestions: value.targetQuestions,
                        ),
                        builder: (context, state, _) {
                          final dailyRun = _maybeRead<DailyRunProvider>(
                            context,
                          );
                          final comboText = dailyRun?.comboText;
                          final comboLabel = comboText == null
                              ? null
                              : comboText == 'On fire!'
                              ? '⚡ On fire!'
                              : '🔥 Combo!';
                          return DailyRunProgressStrip(
                            stageLabel: _stageLabelForIndex(_runStageIndex),
                            stageIndex: _runStageIndex,
                            totalStages: _runPlans.length,
                            progressText:
                                'Gate ${state.questionIndex + 1}/${state.targetQuestions}',
                            correctStreak: dailyRun?.correctStreak ?? 0,
                            comboText: comboLabel,
                            xpMultiplier:
                                dailyRun?.displayedXpMultiplier ?? 1.0,
                            lastXpGain: _latestXpGain,
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    Selector<
                      AdaptivePracticeProvider,
                      ({double before, double after})
                    >(
                      selector: (_, value) => (
                        before: value.masteryBefore,
                        after: value.masteryAfter,
                      ),
                      builder: (context, mastery, _) {
                        return MasteryInlineMeter(
                          before: mastery.before,
                          after: mastery.after,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Selector<AdaptivePracticeProvider, Duration>(
                      selector: (_, value) => value.retryCountdown,
                      builder: (context, remaining, _) {
                        return PracticeRateLimitBanner(remaining: remaining);
                      },
                    ),
                    Selector<AdaptivePracticeProvider, String?>(
                      selector: (_, value) => value.error,
                      builder: (context, error, _) {
                        if (error == null || error.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child:
                          Selector<
                            AdaptivePracticeProvider,
                            ({
                              bool loading,
                              int questionIndex,
                              int targetQuestions,
                              String prompt,
                              List<String> options,
                            })
                          >(
                            selector: (_, value) => (
                              loading: value.loading,
                              questionIndex: value.questionIndex,
                              targetQuestions: value.targetQuestions,
                              prompt: value.currentQuestion?.prompt ?? '',
                              options:
                                  value.currentQuestion?.options ?? const [],
                            ),
                            builder: (context, state, _) {
                              if (state.loading && state.prompt.isEmpty) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (state.prompt.isEmpty) {
                                return const Center(
                                  child: Text('Getting your gates ready...'),
                                );
                              }

                              return SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    PracticeQuestionCard(
                                      prompt: state.prompt,
                                      questionNumber: state.questionIndex + 1,
                                      totalQuestions: state.targetQuestions,
                                      useGateCopy: _isDailyRunMode,
                                    ),
                                    const SizedBox(height: 12),
                                    Selector<
                                      AdaptivePracticeProvider,
                                      ({
                                        bool submitting,
                                        String? selected,
                                        bool? isCorrect,
                                      })
                                    >(
                                      selector: (_, value) => (
                                        submitting: value.submitting,
                                        selected: _selectedOption,
                                        isCorrect:
                                            value.lastAnswerResponse?.isCorrect,
                                      ),
                                      builder: (context, selection, _) {
                                        return PracticeOptionsList(
                                          options: state.options,
                                          enabled:
                                              !selection.submitting &&
                                              !context
                                                  .read<
                                                    AdaptivePracticeProvider
                                                  >()
                                                  .isRateLimited,
                                          submitting: selection.submitting,
                                          onSelect: (value) {
                                            setState(
                                              () => _selectedOption = value,
                                            );
                                          },
                                          lastSelected: selection.selected,
                                          lastCorrect: selection.isCorrect,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),
                    Selector<
                      AdaptivePracticeProvider,
                      ({String? feedback, bool? correct})
                    >(
                      selector: (_, value) => (
                        feedback: value.lastAnswerResponse?.feedback,
                        correct: value.lastAnswerResponse?.isCorrect,
                      ),
                      builder: (context, feedback, _) {
                        return PracticeFeedbackBar(
                          feedback: _displayFeedback(
                            feedback.feedback,
                            isCorrect: feedback.correct,
                          ),
                          isCorrect: feedback.correct,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Selector<
                      AdaptivePracticeProvider,
                      ({bool submitting, bool rateLimited, bool hasQuestion})
                    >(
                      selector: (_, value) => (
                        submitting: value.submitting,
                        rateLimited: value.isRateLimited,
                        hasQuestion: value.currentQuestion != null,
                      ),
                      builder: (context, buttonState, _) {
                        return PracticeBottomCta(
                          enabled:
                              _selectedOption != null &&
                              buttonState.hasQuestion &&
                              !buttonState.rateLimited,
                          busy: buttonState.submitting,
                          isLastQuestion: _isLastQuestion(
                            context.read<AdaptivePracticeProvider>(),
                          ),
                          onPressed: _submitSelectedAnswer,
                          useGateCopy: _isDailyRunMode,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_showRunOverlay && _runOverlayText != null)
              DailyRunBurstOverlay(
                text: _runOverlayText!,
                subtitle: _runOverlaySubtitle,
                icon: _runOverlayIcon,
                compact: _runOverlayCompact,
              ),
          ],
        ),
      ),
    );
  }

  bool _isLastQuestion(AdaptivePracticeProvider provider) {
    final target = provider.targetQuestions;
    if (target <= 0) return false;
    return provider.questionIndex + 1 >= target;
  }

  Future<void> _playStartBeatThenStart(PracticeLaunchPlan plan) async {
    if (_startBeatRunning) {
      return;
    }
    _startBeatRunning = true;
    await _showRunBurst(
      'Ready?',
      subtitle: 'Clear the gates',
      icon: Icons.flag_rounded,
      duration: const Duration(milliseconds: 420),
      autoHide: false,
    );
    await _showRunBurst(
      _stageLabelForIndex(_runStageIndex),
      subtitle: 'Keep the streak alive',
      icon: Icons.bolt_rounded,
      duration: const Duration(milliseconds: 360),
      autoHide: false,
    );

    for (final text in const ['3', '2', '1', 'Go!']) {
      await _showRunBurst(
        text,
        duration: const Duration(milliseconds: 250),
        autoHide: false,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() => _showRunOverlay = false);
    context.read<AdaptivePracticeProvider>().start(plan);
    _startBeatRunning = false;
  }

  Future<void> _showRunBurst(
    String text, {
    String? subtitle,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 760),
    bool compact = false,
    bool autoHide = true,
  }) async {
    _runOverlayTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _runOverlayText = text;
      _runOverlaySubtitle = subtitle;
      _runOverlayIcon = icon;
      _runOverlayCompact = compact;
      _showRunOverlay = true;
    });

    if (autoHide) {
      _runOverlayTimer = Timer(duration, () {
        if (!mounted) {
          return;
        }
        setState(() => _showRunOverlay = false);
      });
    }

    await Future<void>.delayed(duration);
  }

  Future<void> _submitSelectedAnswer() async {
    final selectedOption = _selectedOption;
    if (selectedOption == null) {
      return;
    }

    final provider = context.read<AdaptivePracticeProvider>();
    final shownAt = provider.questionShownAt ?? DateTime.now();
    final response = await provider.answer(selectedOption);
    if (!mounted || response == null) {
      return;
    }

    if (response.isCorrect) {
      unawaited(HapticFeedback.lightImpact());
    } else {
      unawaited(HapticFeedback.selectionClick());
    }

    if (_isDailyRunMode) {
      _applyDailyRunAnswerPolish(
        isCorrect: response.isCorrect,
        shownAt: shownAt,
      );
      setState(() {
        _latestXpGain = response.xpEarned > 0 ? response.xpEarned : null;
      });
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) {
          return;
        }
        setState(() => _latestXpGain = null);
      });
    }

    setState(() => _selectedOption = null);
  }

  void _applyDailyRunAnswerPolish({
    required bool isCorrect,
    required DateTime shownAt,
  }) {
    final dailyRun = _maybeRead<DailyRunProvider>(context);
    if (dailyRun != null) {
      unawaited(dailyRun.registerAnswerResult(isCorrect: isCorrect));
    }

    if (isCorrect) {
      _runCorrectStreak += 1;
      final wasFast =
          DateTime.now().difference(shownAt) <=
          const Duration(milliseconds: 3500);
      _quickCorrectStreak = wasFast ? _quickCorrectStreak + 1 : 0;

      if (_runCorrectStreak == 8) {
        unawaited(_showRunBurst('Unstoppable!', icon: Icons.flash_on_rounded));
      } else if (_runCorrectStreak == 5) {
        unawaited(
          _showRunBurst(
            'On Fire x3',
            icon: Icons.local_fire_department_rounded,
          ),
        );
      } else if (_runCorrectStreak == 3) {
        unawaited(_showRunBurst('Combo x2', icon: Icons.whatshot_rounded));
      } else if (_quickCorrectStreak == 3) {
        unawaited(
          _showRunBurst(
            'Speed streak!',
            icon: Icons.speed_rounded,
            compact: true,
          ),
        );
      } else if (wasFast) {
        unawaited(
          _showRunBurst('Fast hit!', icon: Icons.bolt_rounded, compact: true),
        );
      }
      return;
    }

    _runCorrectStreak = 0;
    _quickCorrectStreak = 0;
    _mistakeCopyIndex += 1;
    unawaited(
      _showRunBurst(
        'Combo reset',
        subtitle: 'Shake it off',
        icon: Icons.refresh_rounded,
        compact: true,
      ),
    );
  }

  String? _displayFeedback(String? feedback, {required bool? isCorrect}) {
    if (!_isDailyRunMode || isCorrect != false) {
      return feedback;
    }
    return _mistakeCopy();
  }

  String _mistakeCopy() {
    const options = ['Close one', 'Shake it off', 'Combo reset'];
    return options[_mistakeCopyIndex % options.length];
  }

  Future<void> _confirmExit() async {
    final provider = context.read<AdaptivePracticeProvider>();
    if (provider.isComplete || provider.sessionId == null) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
      return;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isDailyRunMode ? 'Exit Daily Run?' : 'Exit challenge?'),
          content: Text(
            _isDailyRunMode
                ? 'Your gates will reset when you start a new run.'
                : 'Your saved progress will stay here and this round will end.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continue'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    if (shouldExit != true || !mounted) {
      return;
    }
    await provider.complete();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _handleCompletion(PracticeCompleteResponse completion) async {
    _handledCompletionSessionId = completion.sessionId;
    if (!_isDailyRunMode) {
      await _presentSummary(completion);
      return;
    }

    _accumulateRunStats(completion);

    final nextStageIndex = _runStageIndex + 1;
    if (nextStageIndex < _runPlans.length) {
      if (_runStageIndex == 0) {
        await _showRunBurst(
          'Warm-up cleared',
          icon: Icons.check_circle_rounded,
          duration: const Duration(milliseconds: 760),
        );
      } else if (_runStageIndex == 1) {
        await _showRunBurst(
          'Final Gate unlocked',
          subtitle: 'Crack the chest',
          icon: Icons.card_giftcard_rounded,
          duration: const Duration(milliseconds: 900),
        );
      }

      setState(() {
        _runStageIndex = nextStageIndex;
        _selectedOption = null;
      });
      final dailyRun = _maybeRead<DailyRunProvider>(context);
      if (dailyRun != null) {
        await dailyRun.moveToStage(nextStageIndex);
      }
      if (!mounted) {
        return;
      }
      if (nextStageIndex == 2) {
        await _showRunBurst(
          'Final Gate',
          subtitle: 'Chest is waiting',
          icon: Icons.card_giftcard_rounded,
          duration: const Duration(milliseconds: 520),
        );
      }
      await context.read<AdaptivePracticeProvider>().start(_currentPlan);
      return;
    }

    final dailyRun = _maybeRead<DailyRunProvider>(context);
    if (dailyRun != null) {
      await dailyRun.markCompleted();
    }
    await _presentDailyRunCompletion(_buildRunSummary(completion));
  }

  void _accumulateRunStats(PracticeCompleteResponse completion) {
    if (!_runStatsInitialized) {
      _runStatsInitialized = true;
      _runInitialMastery = completion.initialMastery;
    }
    _runTotalXp += completion.xpEarned;
    _runAnsweredQuestions += completion.answeredQuestions;
    _runCorrectAnswers += completion.correctAnswers;
    _runMasteryDelta += completion.masteryDelta;
    _runFinalMastery = completion.finalMastery;
  }

  PracticeCompleteResponse _buildRunSummary(
    PracticeCompleteResponse finalStageCompletion,
  ) {
    final answered = _runAnsweredQuestions;
    final accuracy = answered == 0 ? 0.0 : _runCorrectAnswers / answered;
    return PracticeCompleteResponse(
      sessionId: finalStageCompletion.sessionId,
      status: finalStageCompletion.status,
      answeredQuestions: answered,
      correctAnswers: _runCorrectAnswers,
      accuracy: accuracy,
      xpEarned: _runTotalXp,
      initialMastery: _runInitialMastery,
      finalMastery: _runFinalMastery,
      masteryDelta: _runMasteryDelta,
      weakTopicsUpdated: finalStageCompletion.weakTopicsUpdated,
      recommendedNextSkillNodeId:
          finalStageCompletion.recommendedNextSkillNodeId,
    );
  }

  Future<void> _presentDailyRunCompletion(
    PracticeCompleteResponse completion,
  ) async {
    _summaryPresented = true;
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, __, ___) => DailyRunCompletionPage(
          onOpenChest: () async {
            Navigator.of(context).pop();
            await _syncProgressAfterCompletion(completion);
            if (!mounted) {
              return;
            }
            context.goLearnMap(focusNodeId: _currentPlan.nodeId);
          },
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  Future<void> _presentSummary(PracticeCompleteResponse completion) async {
    _summaryPresented = true;

    // ── Step 1: Celebration overlay ───────────────────────────────────────
    if (mounted) {
      await Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          opaque: true,
          pageBuilder: (_, __, ___) => PracticeCelebrationPage(
            xpEarned: completion.xpEarned,
            correctCount: completion.correctAnswers,
            totalQuestions: completion.answeredQuestions,
            masteryDelta: completion.masteryDelta,
            onContinue: () => Navigator.of(context).pop(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 220),
        ),
      );
    }

    if (!mounted) return;

    // ── Step 2: Detailed summary sheet ────────────────────────────────────
    final nextNodeId = completion.recommendedNextSkillNodeId;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (sheetContext) {
        return PracticeSummarySheet(
          summary: completion,
          onBackToMap: () async {
            await _syncProgressAfterCompletion(completion);
            if (!mounted) return;
            Navigator.of(sheetContext).pop();
            context.goLearnMap(focusNodeId: _currentPlan.nodeId);
          },
          onPracticeNext: nextNodeId == null
              ? null
              : () async {
                  await _syncProgressAfterCompletion(completion);
                  if (!mounted) return;
                  Navigator.of(sheetContext).pop();
                  context.goLearnMap(focusNodeId: nextNodeId);
                },
          headline: _isDailyRunMode ? 'You beat today\'s run! 🎉' : null,
        );
      },
    );
  }

  Future<void> _syncProgressAfterCompletion(
    PracticeCompleteResponse completion,
  ) async {
    final progress = _maybeRead<ProgressProvider>(context);
    if (progress == null) {
      return;
    }

    try {
      await progress.applyPracticeRoundReward(xpEarned: completion.xpEarned);
    } catch (error, stackTrace) {
      debugPrint('Failed to sync adaptive practice reward locally: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _stageLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Warm-up';
      case 1:
        return 'Challenge';
      case 2:
      default:
        return 'Final Gate';
    }
  }
}

T? _maybeRead<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.signal_wifi_connected_no_internet_4_rounded,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: onBack,
                child: const Text('Back to my map'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ],
      ),
    );
  }
}
