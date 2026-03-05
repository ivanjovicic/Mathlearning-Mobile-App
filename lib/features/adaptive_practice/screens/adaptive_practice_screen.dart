import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/adaptive_practice/providers/adaptive_practice_provider.dart';
import 'package:mathlearning/features/adaptive_practice/providers/parent_dashboard_refresh_bridge.dart';
import 'package:mathlearning/features/adaptive_practice/services/practice_session_api_service.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/mastery_inline_meter.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_bottom_cta.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_feedback_bar.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_options_list.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_question_card.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_rate_limit_banner.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_summary_sheet.dart';
import 'package:mathlearning/features/adaptive_practice/widgets/practice_top_bar.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/services/api_service.dart';

class AdaptivePracticeScreen extends StatelessWidget {
  const AdaptivePracticeScreen({
    super.key,
    required this.plan,
    this.providerOverride,
  });

  final PracticeLaunchPlan plan;
  final AdaptivePracticeProvider? providerOverride;

  @override
  Widget build(BuildContext context) {
    final provider = providerOverride;
    if (provider != null) {
      return ChangeNotifierProvider<AdaptivePracticeProvider>.value(
        value: provider,
        child: _AdaptivePracticeView(plan: plan),
      );
    }

    final learningMapProvider = _maybeRead<LearningMapProvider>(context);
    if (learningMapProvider == null) {
      return const Scaffold(
        body: Center(child: Text('Learning map is unavailable.')),
      );
    }

    final dashboardBridge = _maybeRead<ParentDashboardRefreshBridge>(context);

    return ChangeNotifierProvider<AdaptivePracticeProvider>(
      create: (_) => AdaptivePracticeProvider(
        apiService: PracticeSessionApiService(apiService: ApiService()),
        learningMapRefresher: LearningMapRefresherAdapter(learningMapProvider),
        refreshParentDashboard: dashboardBridge?.refreshAll,
      ),
      child: _AdaptivePracticeView(plan: plan),
    );
  }
}

class _AdaptivePracticeView extends StatefulWidget {
  const _AdaptivePracticeView({required this.plan});

  final PracticeLaunchPlan plan;

  @override
  State<_AdaptivePracticeView> createState() => _AdaptivePracticeViewState();
}

class _AdaptivePracticeViewState extends State<_AdaptivePracticeView> {
  bool _initialized = false;
  bool _summaryPresented = false;
  String? _selectedOption;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdaptivePracticeProvider>().start(widget.plan);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdaptivePracticeProvider>();
    final completion = provider.completion;
    if (completion != null && !_summaryPresented) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _summaryPresented) return;
        _presentSummary(completion);
      });
    }

    final error = provider.error;
    if (error != null &&
        provider.currentQuestion == null &&
        !provider.loading &&
        provider.sessionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adaptive Practice')),
        body: _ErrorState(
          message: error,
          onRetry: () =>
              context.read<AdaptivePracticeProvider>().start(widget.plan),
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                Selector<AdaptivePracticeProvider, double>(
                  selector: (_, value) => value.progress,
                  builder: (context, progress, _) {
                    return PracticeTopBar(
                      skillTitle: widget.plan.skillTitle,
                      progress: progress,
                      onClosePressed: _confirmExit,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Selector<
                  AdaptivePracticeProvider,
                  ({double before, double after})
                >(
                  selector: (_, value) =>
                      (before: value.masteryBefore, after: value.masteryAfter),
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
                          options: value.currentQuestion?.options ?? const [],
                        ),
                        builder: (context, state, _) {
                          if (state.loading && state.prompt.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state.prompt.isEmpty) {
                            return const Center(
                              child: Text('Preparing questions...'),
                            );
                          }

                          return SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PracticeQuestionCard(
                                  prompt: state.prompt,
                                  questionNumber: state.questionIndex + 1,
                                  totalQuestions: state.targetQuestions,
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
                                              .read<AdaptivePracticeProvider>()
                                              .isRateLimited,
                                      submitting: selection.submitting,
                                      onSelect: (value) {
                                        setState(() => _selectedOption = value);
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
                      feedback: feedback.feedback,
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
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isLastQuestion(AdaptivePracticeProvider provider) {
    final target = provider.targetQuestions;
    if (target <= 0) return false;
    return provider.questionIndex + 1 >= target;
  }

  Future<void> _submitSelectedAnswer() async {
    final selectedOption = _selectedOption;
    if (selectedOption == null) {
      return;
    }

    final provider = context.read<AdaptivePracticeProvider>();
    final response = await provider.answer(selectedOption);
    if (!mounted || response == null) {
      return;
    }

    if (response.isCorrect) {
      unawaited(HapticFeedback.lightImpact());
    } else {
      unawaited(HapticFeedback.selectionClick());
    }

    setState(() => _selectedOption = null);
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
          title: const Text('Exit practice?'),
          content: const Text(
            'Exit practice? Your progress will be saved and session will end.',
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

  Future<void> _presentSummary(PracticeCompleteResponse completion) async {
    _summaryPresented = true;
    final nextNodeId = completion.recommendedNextSkillNodeId;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (context) {
        return PracticeSummarySheet(
          summary: completion,
          onBackToMap: () {
            Navigator.of(context).pop();
            if (mounted) {
              context.go('/learning-map?focus=${widget.plan.nodeId}');
            }
          },
          onPracticeNext: nextNodeId == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  if (mounted) {
                    context.go('/learning-map?focus=$nextNodeId');
                  }
                },
        );
      },
    );
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
              OutlinedButton(onPressed: onBack, child: const Text('Back')),
              const SizedBox(width: 8),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ],
      ),
    );
  }
}
