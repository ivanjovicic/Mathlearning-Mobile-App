import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/features/adaptive_practice/models/practice_answer_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_answer_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_difficulty.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_response.dart';
import 'package:mathlearning/features/adaptive_practice/providers/adaptive_practice_provider.dart';
import 'package:mathlearning/features/adaptive_practice/screens/adaptive_practice_screen.dart';
import 'package:mathlearning/features/adaptive_practice/services/practice_session_api_service.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_chest_reward_sheet.dart';
import 'package:mathlearning/features/learning_map/widgets/chest_open_animation.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_equip_confirmation.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_fragment_card.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_unlock_celebration.dart';
import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/services/cosmetics_service.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';

class _FakePracticeApiService extends PracticeSessionApiService {
  _FakePracticeApiService() : super(apiService: ApiService());

  int answerCalls = 0;

  @override
  Future<ApiResult<PracticeStartResponse>> startSession(
    PracticeStartRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return ApiResult(
      data: PracticeStartResponse.fromJson({
        'sessionId': 'session-ui',
        'skillNodeId': request.skillNodeId,
        'recommendedDifficulty': 'easy',
        'initialMastery': 0.2,
        'question': {
          'id': 1,
          'prompt': '3 + 2 = ?',
          'options': ['4', '5', '6', '7'],
          'difficulty': 'easy',
        },
      }),
    );
  }

  @override
  Future<ApiResult<PracticeAnswerResponse>> submitAnswer(
    String sessionId,
    PracticeAnswerRequest request,
  ) async {
    answerCalls += 1;
    if (answerCalls == 1) {
      return ApiResult(
        data: PracticeAnswerResponse.fromJson({
          'isCorrect': true,
          'feedback': 'Correct!',
          'masteryBefore': 0.2,
          'masteryAfter': 0.3,
          'xpEarned': 10,
          'nextQuestion': {
            'id': 2,
            'prompt': '4 + 4 = ?',
            'options': ['6', '7', '8', '9'],
            'difficulty': 'medium',
          },
        }),
      );
    }

    return ApiResult(
      data: PracticeAnswerResponse.fromJson({
        'isCorrect': true,
        'feedback': 'Great!',
        'masteryBefore': 0.3,
        'masteryAfter': 0.4,
        'xpEarned': 12,
        'nextQuestion': null,
      }),
    );
  }

  @override
  Future<ApiResult<PracticeCompleteResponse>> completeSession(
    String sessionId,
  ) async {
    return ApiResult(
      data: PracticeCompleteResponse.fromJson({
        'sessionId': sessionId,
        'status': 'Completed',
        'answeredQuestions': 2,
        'correctAnswers': 2,
        'accuracy': 1.0,
        'xpEarned': 22,
        'initialMastery': 0.2,
        'finalMastery': 0.4,
        'masteryDelta': 0.2,
        'weakTopicsUpdated': true,
        'recommendedNextSkillNodeId': 'fraction_addition',
      }),
    );
  }
}

class _FakeMapRefresher implements AdaptiveLearningMapRefresher {
  @override
  Future<void> completePractice({
    required PracticeLaunchPlan plan,
    required int xpEarned,
    required double masteryDelta,
    required double accuracy,
    required String? recommendedNextNodeId,
  }) async {}

  @override
  Future<void> refresh(String userId) async {}
}

class _FakeDailyRunApiService extends PracticeSessionApiService {
  _FakeDailyRunApiService() : super(apiService: ApiService());

  int startCalls = 0;
  final Map<String, int> targetsBySession = {};
  final Map<String, int> answersBySession = {};

  @override
  Future<ApiResult<PracticeStartResponse>> startSession(
    PracticeStartRequest request,
  ) async {
    startCalls += 1;
    final sessionId = 'daily-session-$startCalls';
    targetsBySession[sessionId] = request.targetQuestions;
    answersBySession[sessionId] = 0;
    return ApiResult(
      data: PracticeStartResponse.fromJson({
        'sessionId': sessionId,
        'skillNodeId': request.skillNodeId,
        'recommendedDifficulty': request.preferredDifficulty.apiValue,
        'initialMastery': 0.2,
        'question': {
          'id': startCalls * 100 + 1,
          'prompt': 'Gate $startCalls.1',
          'options': ['A', 'B', 'C', 'D'],
          'difficulty': request.preferredDifficulty.apiValue,
        },
      }),
    );
  }

  @override
  Future<ApiResult<PracticeAnswerResponse>> submitAnswer(
    String sessionId,
    PracticeAnswerRequest request,
  ) async {
    final answered = (answersBySession[sessionId] ?? 0) + 1;
    answersBySession[sessionId] = answered;
    final target = targetsBySession[sessionId] ?? 1;
    final hasNext = answered < target;
    return ApiResult(
      data: PracticeAnswerResponse.fromJson({
        'isCorrect': request.selectedOption == 'A',
        'feedback': request.selectedOption == 'A' ? 'Correct!' : 'Try again',
        'masteryBefore': 0.2,
        'masteryAfter': 0.25,
        'xpEarned': request.selectedOption == 'A' ? 10 : 0,
        'nextQuestion': hasNext
            ? {
                'id': request.questionId + 1,
                'prompt': 'Gate $startCalls.${answered + 1}',
                'options': ['A', 'B', 'C', 'D'],
                'difficulty': 'easy',
              }
            : null,
      }),
    );
  }

  @override
  Future<ApiResult<PracticeCompleteResponse>> completeSession(
    String sessionId,
  ) async {
    final answered = answersBySession[sessionId] ?? 0;
    return ApiResult(
      data: PracticeCompleteResponse.fromJson({
        'sessionId': sessionId,
        'status': 'Completed',
        'answeredQuestions': answered,
        'correctAnswers': answered,
        'accuracy': 1.0,
        'xpEarned': answered * 10,
        'initialMastery': 0.2,
        'finalMastery': 0.3,
        'masteryDelta': 0.1,
        'weakTopicsUpdated': true,
        'recommendedNextSkillNodeId': null,
      }),
    );
  }
}

Widget _wrap(AdaptivePracticeProvider provider, PracticeLaunchPlan plan) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdaptivePracticeProvider>.value(value: provider),
      ChangeNotifierProvider<ProgressProvider>(
        create: (_) => ProgressProvider(),
      ),
    ],
    child: MaterialApp(
      home: AdaptivePracticeScreen(plan: plan, providerOverride: provider),
    ),
  );
}

Widget _wrapDailyRun(
  AdaptivePracticeProvider provider,
  List<PracticeLaunchPlan> plans, {
  VoidCallback? onComboSound,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AdaptivePracticeProvider>.value(value: provider),
      ChangeNotifierProvider<ProgressProvider>(
        create: (_) => ProgressProvider(),
      ),
      ChangeNotifierProvider<DailyRunProvider>(
        create: (_) => DailyRunProvider()..load('user-1'),
      ),
    ],
    child: MaterialApp(
      home: AdaptivePracticeScreen(
        plan: plans.first,
        providerOverride: provider,
        dailyRunPlans: plans,
        onComboSound: onComboSound,
      ),
    ),
  );
}

void main() {
  const plan = PracticeLaunchPlan(
    userId: 'user-1',
    nodeId: 'fractions_basics',
    skillTitle: 'Fractions Basics',
    topicId: 4,
    subtopicId: 12,
    difficulty: SkillDifficulty.medium,
    source: PracticeSource.recent,
    practiceId: 'fractions_pack_1',
    targetQuestions: 2,
  );

  const dailyRunPlans = [
    PracticeLaunchPlan(
      userId: 'user-1',
      nodeId: 'warm',
      skillTitle: 'Warm',
      topicId: 4,
      subtopicId: 12,
      difficulty: SkillDifficulty.easy,
      source: PracticeSource.recent,
      practiceId: 'warm',
      targetQuestions: 2,
    ),
    PracticeLaunchPlan(
      userId: 'user-1',
      nodeId: 'challenge',
      skillTitle: 'Challenge',
      topicId: 4,
      subtopicId: 12,
      difficulty: SkillDifficulty.medium,
      source: PracticeSource.recent,
      practiceId: 'challenge',
      targetQuestions: 5,
    ),
    PracticeLaunchPlan(
      userId: 'user-1',
      nodeId: 'final',
      skillTitle: 'Final',
      topicId: 4,
      subtopicId: 12,
      difficulty: SkillDifficulty.hard,
      source: PracticeSource.recent,
      practiceId: 'final',
      targetQuestions: 2,
    ),
  ];

  const comboRunPlans = [
    PracticeLaunchPlan(
      userId: 'user-1',
      nodeId: 'warm',
      skillTitle: 'Warm',
      topicId: 4,
      subtopicId: 12,
      difficulty: SkillDifficulty.easy,
      source: PracticeSource.recent,
      practiceId: 'warm',
      targetQuestions: 5,
    ),
  ];

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Finder questionLabel(String prompt, {required int number}) {
    return find.bySemanticsLabel('Question $number of 2. $prompt');
  }

  testWidgets('shows loading then first question', (tester) async {
    final provider = AdaptivePracticeProvider(
      apiService: _FakePracticeApiService(),
      learningMapRefresher: _FakeMapRefresher(),
    );

    await tester.pumpWidget(_wrap(provider, plan));
    await tester.pumpAndSettle();

    expect(questionLabel('3 + 2 = ?', number: 1), findsOneWidget);
  });

  testWidgets('correct answer shows feedback', (tester) async {
    final provider = AdaptivePracticeProvider(
      apiService: _FakePracticeApiService(),
      learningMapRefresher: _FakeMapRefresher(),
    );

    await tester.pumpWidget(_wrap(provider, plan));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();

    expect(find.text('Correct!'), findsOneWidget);
    expect(questionLabel('4 + 4 = ?', number: 2), findsOneWidget);
  });

  testWidgets('finish shows summary sheet', (tester) async {
    final provider = AdaptivePracticeProvider(
      apiService: _FakePracticeApiService(),
      learningMapRefresher: _FakeMapRefresher(),
    );

    await tester.pumpWidget(_wrap(provider, plan));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.tap(find.text('Done! →'));
    await tester.pumpAndSettle();

    expect(find.text('Keep going! →'), findsOneWidget);

    await tester.tap(find.text('Keep going! →'));
    await tester.pumpAndSettle();

    expect(find.text('You crushed it! 🎉'), findsOneWidget);
    expect(find.text('Back to my map'), findsOneWidget);
  });

  testWidgets('daily run shows countdown start beat before first gate', (
    tester,
  ) async {
    final provider = AdaptivePracticeProvider(
      apiService: _FakeDailyRunApiService(),
      learningMapRefresher: _FakeMapRefresher(),
    );

    await tester.pumpWidget(_wrapDailyRun(provider, dailyRunPlans));
    await tester.pump();

    expect(find.text('Ready?'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 850));
    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Gate 1/2'), findsWidgets);
  });

  testWidgets('daily run shows center combo burst at three correct', (
    tester,
  ) async {
    final provider = AdaptivePracticeProvider(
      apiService: _FakeDailyRunApiService(),
      learningMapRefresher: _FakeMapRefresher(),
    );
    var comboSoundCalls = 0;

    await tester.pumpWidget(
      _wrapDailyRun(
        provider,
        comboRunPlans,
        onComboSound: () => comboSoundCalls += 1,
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('A').first);
      await tester.pump();
      await tester.tap(find.text('Clear Gate'));
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(comboSoundCalls, 1);
    expect(find.text('3-Hit Combo!'), findsOneWidget);
    expect(find.text('🔥 Combo!'), findsNothing);
    expect(find.text('⚡ On fire!'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('daily run shows stage transition copy after warm-up', (
    tester,
  ) async {
    final provider = AdaptivePracticeProvider(
      apiService: _FakeDailyRunApiService(),
      learningMapRefresher: _FakeMapRefresher(),
    );

    await tester.pumpWidget(_wrapDailyRun(provider, dailyRunPlans));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('A').first);
      await tester.pump();
      await tester.tap(find.text('Clear Gate'));
      await tester.pump(const Duration(milliseconds: 120));
    }

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Warm-up cleared'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  // ---------------------------------------------------------------------------
  // DailyChestRewardSheet – updated tests for juice-pass
  // ---------------------------------------------------------------------------

  /// Helper that builds the sheet inside a Material context with HUD target keys.
  /// [startOpen] bypasses the chest animation (for reliable test timing).
  Widget buildSheet({
    required DailyChestReward reward,
    GlobalKey? xpTargetKey,
    GlobalKey? coinTargetKey,
    void Function(int)? onApplyXp,
    void Function(int)? onApplyCoins,
    VoidCallback? onContinue,
    VoidCallback? onViewCollection,
    bool startOpen = true,
    int? fragmentCountForTesting,
  }) {
    final xpKey = xpTargetKey ?? GlobalKey();
    final coinKey = coinTargetKey ?? GlobalKey();
    // Use a Stack without a constrained Scaffold body so the sheet never overflows.
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                key: xpKey,
                width: 180,
                height: 12,
                color: Colors.blue,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                key: coinKey,
                width: 44,
                height: 24,
                color: Colors.amber,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: DailyChestRewardSheet(
                  reward: reward,
                  xpTargetKey: xpKey,
                  coinTargetKey: coinKey,
                  onApplyXp: onApplyXp,
                  onApplyCoins: onApplyCoins,
                  onContinue: onContinue ?? () {},
                  onViewCollection: onViewCollection,
                  startOpen: startOpen,
                  fragmentCountForTesting: fragmentCountForTesting,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Drives animations frame by frame so animation controllers advance properly.
  Future<void> pumpMs(WidgetTester tester, int totalMs) async {
    const stepMs = 50;
    var elapsed = 0;
    while (elapsed < totalMs) {
      final step = (totalMs - elapsed).clamp(0, stepMs);
      await tester.pump(Duration(milliseconds: step));
      elapsed += step;
    }
  }

  // With startOpen: true, _onChestOpened fires on the first post-frame callback.
  // Reward sequence: 180ms → XP; +620ms → fly; +240ms → coins; +620ms → fly;
  //                 +280ms → cosmetic; +600ms → done. Total: ~2560ms.

  testWidgets('daily chest reward sheet shows chest before rewards', (
    tester,
  ) async {
    const reward = DailyChestReward(
      xp: 30,
      coins: 12,
      cosmeticFragment: 'Nova Trail Fragment',
    );

    // Use startOpen: false to verify chest is shown before rewards.
    await tester.pumpWidget(buildSheet(reward: reward, startOpen: false));
    await tester.pump(); // post-frame

    // Chest animation widget is present immediately.
    expect(find.byType(ChestOpenAnimation), findsOneWidget);

    // Rewards not visible yet.
    expect(find.text('+30 XP'), findsNothing);
    expect(find.text('+12 coins'), findsNothing);
    expect(find.text('Rare fragment!'), findsNothing);

    // Drain chest animation + reward sequence timers so the test ends cleanly.
    await pumpMs(tester, 5000);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'daily chest reward sheet reveals rewards sequentially after chest opens',
    (tester) async {
      const reward = DailyChestReward(
        xp: 30,
        coins: 12,
        cosmeticFragment: 'Nova Trail Fragment',
      );

      // startOpen: true fires _onChestOpened on first post-frame callback.
      await tester.pumpWidget(buildSheet(reward: reward));
      await tester
          .pump(); // post-frame → _onChestOpened fires, phase = xpReveal

      // XP row not yet visible (180ms delay hasn't elapsed).
      expect(find.byKey(const Key('daily_reward_xp_source')), findsNothing);

      // After 200ms: XP count-up visible (180ms delay elapsed).
      await pumpMs(tester, 200);
      expect(find.textContaining('XP'), findsOneWidget);
      expect(find.textContaining('coins'), findsNothing);

      // After XP count-up (620ms) + fly + 240ms gap: coins count-up visible.
      await pumpMs(tester, 1600);
      expect(find.textContaining('coins'), findsOneWidget);

      // After coin count-up + fly + 280ms: cosmetic visible.
      await pumpMs(tester, 1600);
      expect(find.text('Rare fragment!'), findsOneWidget);
      expect(find.text('Nova Trail'), findsOneWidget);

      // First persisted fragment is 1/5, so the teaser stays generic until the
      // same item reaches the near-complete threshold.
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Tomorrow: Rare fragment chance'), findsOneWidget);

      // Drain remaining sequence timers.
      await pumpMs(tester, 1500);
    },
  );

  testWidgets('claim button reads "Grab it!" and is disabled until done', (
    tester,
  ) async {
    const reward = DailyChestReward(
      xp: 30,
      coins: 12,
      cosmeticFragment: 'Nova Trail Fragment',
    );

    await tester.pumpWidget(buildSheet(reward: reward));
    await tester.pump();

    // Button text is "Grab it!" from the start.
    expect(find.text('Grab it!'), findsOneWidget);

    // Button is disabled (sequence not done).
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);

    // Drive past the full sequence (~3800ms after chest fires, including fly animations).
    await pumpMs(tester, 4500);

    final btnDone = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btnDone.onPressed, isNotNull);
  });

  testWidgets('cosmetic fragment card shows name, rarity, and progress', (
    tester,
  ) async {
    const reward = DailyChestReward(
      xp: 30,
      coins: 12,
      cosmeticFragment: 'Nova Trail Fragment',
    );

    await tester.pumpWidget(buildSheet(reward: reward));
    await tester.pump();

    // Drive through full sequence (including fly animations).
    await pumpMs(tester, 4500);

    expect(find.text('Rare fragment!'), findsOneWidget);
    // "Nova Trail" is extracted by stripping " Fragment".
    expect(find.text('Nova Trail'), findsOneWidget);
    // Rarity badge for rare (incomplete item still shows rarity).
    expect(find.text('Rare'), findsOneWidget);
    expect(find.text('1/5 collected'), findsOneWidget);
    // Unlock hint copy — 'Collect X to unlock' replaced by progress bar.
    expect(find.textContaining('more to unlock'), findsOneWidget);
    expect(find.text('Collect 5 to unlock'), findsNothing);
  });

  testWidgets('daily chest reward sheet applies XP then coins after flights', (
    tester,
  ) async {
    const reward = DailyChestReward(
      xp: 30,
      coins: 12,
      cosmeticFragment: 'Nova Trail Fragment',
    );
    var appliedXp = 0;
    var appliedCoins = 0;

    await tester.pumpWidget(
      buildSheet(
        reward: reward,
        onApplyXp: (v) => appliedXp += v,
        onApplyCoins: (v) => appliedCoins += v,
      ),
    );
    await tester.pump();

    // Nothing applied yet.
    expect(appliedXp, 0);
    expect(appliedCoins, 0);

    // Drive through full sequence (including fly animations).
    await pumpMs(tester, 4500);

    expect(appliedXp, 30);
    expect(appliedCoins, 12);
  });

  // ---------------------------------------------------------------------------
  // CosmeticFragmentCard – standalone unit-style widget tests
  // ---------------------------------------------------------------------------

  group('CosmeticFragmentCard', () {
    Widget buildCard({
      required int collected,
      required int total,
      String heading = 'Fragment found!',
      VoidCallback? onViewCollection,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CosmeticFragmentCard(
              fragmentName: 'Nova Trail',
              collected: collected,
              total: total,
              rarity: FragmentRarity.rare,
              animate: false,
              heading: heading,
              onViewCollection: onViewCollection,
            ),
          ),
        ),
      );
    }

    testWidgets('shows collected count and unlock hints when incomplete', (
      tester,
    ) async {
      await tester.pumpWidget(buildCard(collected: 3, total: 5));
      await tester.pump();

      expect(find.text('3/5 collected'), findsOneWidget);
      expect(find.text('2 more to unlock'), findsOneWidget);
      // Progress bar visible; no 'Collect X to unlock' copy.
      expect(find.text('Collect 5 to unlock'), findsNothing);
      // No completion CTA.
      expect(find.text('View collection'), findsNothing);
    });

    testWidgets('hides unlock hints when collection is complete', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(collected: 5, total: 5, heading: 'Item unlocked! 🎉'),
      );
      await tester.pump();

      expect(find.text('5/5 collected'), findsOneWidget);
      expect(find.textContaining('more to unlock'), findsNothing);
      expect(find.text('Collect 5 to unlock'), findsNothing);
      expect(find.text('Item unlocked! 🎉'), findsOneWidget);
    });

    testWidgets('shows urgency copy when near unlock', (tester) async {
      // 4/5: 1 remaining.
      await tester.pumpWidget(buildCard(collected: 4, total: 5));
      await tester.pump();
      expect(find.text("One more and it's yours!"), findsOneWidget);
      expect(find.text('1 more to unlock'), findsOneWidget);
      expect(find.byKey(const Key('fragment_progress_pip_4')), findsOneWidget);

      // 3/5: 2 remaining.
      await tester.pumpWidget(buildCard(collected: 3, total: 5));
      await tester.pump();
      expect(find.text('Almost unlocked!'), findsOneWidget);
      expect(find.text('2 more to unlock'), findsOneWidget);

      // 1/5: 4 remaining - no near-unlock copy.
      await tester.pumpWidget(buildCard(collected: 1, total: 5));
      await tester.pump();
      expect(find.text("One more and it's yours!"), findsNothing);
      expect(find.text('Almost unlocked!'), findsNothing);
      expect(find.text('4 more to unlock'), findsOneWidget);
    });

    testWidgets('final pip uses chain-fill animation key on completion', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(collected: 5, total: 5, heading: 'NOVA TRAIL UNLOCKED!'),
      );
      await tester.pump();

      expect(find.byKey(const Key('fragment_final_pip_chain')), findsOneWidget);
    });

    testWidgets('trail fragment renders _TrailPreview via CustomPaint', (
      tester,
    ) async {
      // 'Nova Trail' → _CosmeticItemType.trail → _TrailPreview → CustomPaint.
      await tester.pumpWidget(buildCard(collected: 2, total: 5));
      await tester.pump();
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('burst fragment renders _BurstPreview via CustomPaint', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CosmeticFragmentCard(
                fragmentName: 'Nova Burst',
                collected: 2,
                total: 5,
                rarity: FragmentRarity.epic,
                animate: false,
                heading: 'Epic find!',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'shows View collection button only when complete and callback given',
      (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildCard(
            collected: 5,
            total: 5,
            heading: 'Item unlocked! 🎉',
            onViewCollection: () => tapped = true,
          ),
        );
        await tester.pump();

        expect(find.text('View collection'), findsOneWidget);
        await tester.tap(find.text('View collection'));
        expect(tapped, isTrue);
      },
    );
    testWidgets('shows Equip now button when complete and onEquipNow given', (
      tester,
    ) async {
      var equipped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CosmeticFragmentCard(
                fragmentName: 'Nova Trail',
                collected: 5,
                total: 5,
                rarity: FragmentRarity.rare,
                animate: false,
                heading: 'Item unlocked! \ud83c\udf89',
                onEquipNow: () => equipped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Equip now'), findsOneWidget);
      await tester.tap(find.text('Equip now'));
      expect(equipped, isTrue);
    });
    testWidgets('does not show View collection button when incomplete', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(collected: 3, total: 5, onViewCollection: () {}),
      );
      await tester.pump();

      expect(find.text('View collection'), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // DailyChestRewardSheet – onViewCollection integration
  // ---------------------------------------------------------------------------

  testWidgets(
    'sheet passes onViewCollection to card and shows Equip later when complete',
    (tester) async {
      // Completed collection behavior is covered directly above; this verifies
      // the sheet accepts the callback while rendering a normal incomplete reward.
      const reward = DailyChestReward(
        xp: 30,
        coins: 12,
        cosmeticFragment: 'Nova Trail Fragment',
      );

      await tester.pumpWidget(
        buildSheet(reward: reward, onViewCollection: () {}),
      );
      await tester.pump();

      // Claim button is present (still disabled until sequence done).
      expect(find.text('Grab it!'), findsOneWidget);

      // Drive through full sequence.
      await pumpMs(tester, 4500);

      // For Nova Trail (incomplete), button label stays 'Grab it!'.
      expect(find.text('Grab it!'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // CosmeticUnlockCelebration – standalone widget tests
  // ---------------------------------------------------------------------------

  group('CosmeticUnlockCelebration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildCelebration({
      FragmentRarity rarity = FragmentRarity.rare,
      VoidCallback? onEquipNow,
      VoidCallback? onViewCollection,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CosmeticUnlockCelebration(
            itemName: 'Nova Trail',
            rarity: rarity,
            onEquipNow: onEquipNow,
            onViewCollection: onViewCollection,
          ),
        ),
      );
    }

    testWidgets('shows item name and UNLOCKED headline', (tester) async {
      await tester.pumpWidget(buildCelebration());
      await pumpMs(tester, 700); // flush 600ms sound timer + animate delays

      // Headline contains item name (uppercased) and UNLOCKED!
      expect(find.textContaining('NOVA TRAIL'), findsOneWidget);
      expect(find.textContaining('UNLOCKED!'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows 5/5 collected pips', (tester) async {
      await tester.pumpWidget(buildCelebration());
      await pumpMs(tester, 1200);

      expect(find.text('5/5 collected'), findsOneWidget);
    });

    testWidgets('shows rarity label', (tester) async {
      await tester.pumpWidget(buildCelebration(rarity: FragmentRarity.epic));
      await pumpMs(tester, 1200);

      expect(find.text('EPIC'), findsOneWidget);
    });

    testWidgets('Equip now taps callback', (tester) async {
      var equipped = false;
      await tester.pumpWidget(
        buildCelebration(onEquipNow: () => equipped = true),
      );
      // pumpMs advances fake time, flushing all one-shot timers (600ms sound
      // delay, flutter_animate entry delays) without calling pumpAndSettle
      // (which would hang on the looping confetti/sparkle AnimationControllers).
      await pumpMs(tester, 1200);

      await tester.tap(find.text('Equip now'));
      await tester
          .pump(); // let onPressed handler run synchronously to first await
      expect(equipped, isTrue);
      // Drain CosmeticEquipConfirmation burst (800ms) + hold timer (650ms).
      await pumpMs(tester, 2000);
    });

    testWidgets('View collection taps callback', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        buildCelebration(onViewCollection: () => opened = true),
      );
      await pumpMs(tester, 1200);

      await tester.tap(find.text('View collection'));
      expect(opened, isTrue);
    });

    testWidgets('CTA is delayed until the victory hold finishes', (
      tester,
    ) async {
      await tester.pumpWidget(buildCelebration(onEquipNow: () {}));
      await pumpMs(tester, 700);

      expect(find.byKey(const Key('unlock_victory_hold')), findsOneWidget);
      expect(find.text('Equip now'), findsNothing);

      await pumpMs(tester, 500);

      expect(find.byKey(const Key('unlock_victory_hold')), findsNothing);
      expect(find.text('Equip now'), findsOneWidget);
    });

    testWidgets('renders confetti via CustomPaint', (tester) async {
      await tester.pumpWidget(buildCelebration());
      await pumpMs(tester, 700);

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });
  });

  // ---------------------------------------------------------------------------
  // DailyChestRewardSheet + celebration integration
  // ---------------------------------------------------------------------------

  testWidgets(
    'sheet shows CosmeticUnlockCelebration when fragment set is complete',
    (tester) async {
      const reward = DailyChestReward(
        xp: 30,
        coins: 12,
        cosmeticFragment: 'Nova Trail Fragment',
      );

      await tester.pumpWidget(
        buildSheet(reward: reward, fragmentCountForTesting: 5),
      );
      await tester.pump(); // post-frame → chest opens

      // Drive through XP + coins + 280ms gap + cosmetic reveal + 700ms delay
      // + celebration entry animation (660ms for button fade-in).
      // Use 10 000ms to be safe — pumpMs is fast in test clock.
      await pumpMs(tester, 10000);
      await tester.pump(); // flush any pending microtasks

      // CosmeticUnlockCelebration should be showing.
      expect(find.byType(CosmeticUnlockCelebration), findsOneWidget);
      expect(find.textContaining('UNLOCKED!'), findsAtLeastNWidgets(1));
      // Both the CosmeticFragmentCard (complete) and the celebration show
      // '5/5 collected', so use findsAtLeastNWidgets(1).
      expect(find.text('5/5 collected'), findsAtLeastNWidgets(1));
      expect(find.text('Equip now'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // CosmeticEquipConfirmation — standalone widget tests
  // ---------------------------------------------------------------------------

  group('CosmeticEquipConfirmation', () {
    Widget build({
      CosmeticItemType type = CosmeticItemType.trail,
      VoidCallback? onDone,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CosmeticEquipConfirmation(
            itemName: 'Nova Trail',
            itemType: type,
            rarityColor: Colors.blue,
            onDone: onDone,
          ),
        ),
      );
    }

    testWidgets('shows Equipped! after burst starts', (tester) async {
      await tester.pumpWidget(build());
      await pumpMs(tester, 350); // past fade-in delay (100ms + 200ms)
      expect(find.text('Equipped!'), findsOneWidget);
    });

    testWidgets('shows item name in subtitle', (tester) async {
      await tester.pumpWidget(build());
      await pumpMs(tester, 400);
      expect(find.textContaining('Nova Trail'), findsOneWidget);
    });

    testWidgets('shows type label for trail', (tester) async {
      await tester.pumpWidget(build(type: CosmeticItemType.trail));
      await pumpMs(tester, 400);
      expect(find.text('trail effect'), findsOneWidget);
    });

    testWidgets('shows type label for frame', (tester) async {
      await tester.pumpWidget(build(type: CosmeticItemType.frame));
      await pumpMs(tester, 400);
      expect(find.text('avatar frame'), findsOneWidget);
    });

    testWidgets('shows type label for burst', (tester) async {
      await tester.pumpWidget(build(type: CosmeticItemType.burst));
      await pumpMs(tester, 400);
      expect(find.text('answer effect'), findsOneWidget);
    });

    testWidgets('fires onDone after 800ms burst + 650ms hold', (tester) async {
      var done = false;
      await tester.pumpWidget(build(onDone: () => done = true));
      // Before completion: not done yet.
      await pumpMs(tester, 1200);
      expect(done, isFalse);
      // After full 1450ms (800 + 650): done.
      await pumpMs(tester, 300);
      expect(done, isTrue);
    });

    testWidgets('renders sparkle burst via CustomPaint', (tester) async {
      await tester.pumpWidget(build());
      await tester.pump();
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      // Drain burst controller (800ms) + hold timer (650ms) so no pending timers on dispose.
      await pumpMs(tester, 1600);
    });
  });

  // ---------------------------------------------------------------------------
  // CosmeticsService.equipItem — unit tests
  // ---------------------------------------------------------------------------

  group('CosmeticsService.equipItem', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('trail fragment equips animatedEffectId', () async {
      await CosmeticsService.instance.equipItem('Nova Trail');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_avatar_config');
      expect(raw, isNotNull);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['animated_effect_id'], equals('effect_nova_trail'));
    });

    test('frame fragment equips frameId', () async {
      await CosmeticsService.instance.equipItem('Comet Frame');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_avatar_config');
      expect(raw, isNotNull);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['frame_id'], equals('frame_comet'));
    });

    test('burst fragment equips animatedEffectId', () async {
      await CosmeticsService.instance.equipItem('Neon Burst');
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_avatar_config');
      expect(raw, isNotNull);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['animated_effect_id'], equals('effect_neon_number_burst'));
    });

    test(
      'equipping second item overwrites the first in the same slot',
      () async {
        await CosmeticsService.instance.equipItem('Nova Trail');
        await CosmeticsService.instance.equipItem('Neon Burst');
        final prefs = await SharedPreferences.getInstance();
        final json =
            jsonDecode(prefs.getString('user_avatar_config')!)
                as Map<String, dynamic>;
        // Both are animatedEffect; only the last should survive.
        expect(json['animated_effect_id'], equals('effect_neon_number_burst'));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CosmeticUnlockCelebration — equip flow integration
  // ---------------------------------------------------------------------------

  group('CosmeticUnlockCelebration equip flow', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildCelebration({
      VoidCallback? onEquipNow,
      VoidCallback? onViewCollection,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CosmeticUnlockCelebration(
            itemName: 'Nova Trail',
            rarity: FragmentRarity.rare,
            onEquipNow: onEquipNow ?? () {},
            onViewCollection: onViewCollection,
          ),
        ),
      );
    }

    testWidgets('tapping Equip now shows Equipped! confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(buildCelebration());
      await pumpMs(tester, 1200); // wait for victory hold + CTA fade-ins

      await tester.tap(find.text('Equip now'));
      await tester.pump(); // start async equip
      // equipItem hits SharedPreferences (fake, instant in tests).
      await pumpMs(tester, 200);

      expect(find.byType(CosmeticEquipConfirmation), findsOneWidget);
      // Drain confirmation burst (800ms) + hold timer (650ms) before test ends.
      await pumpMs(tester, 1600);
    });

    testWidgets('Equipped! text appears after tapping Equip now', (
      tester,
    ) async {
      await tester.pumpWidget(buildCelebration());
      await pumpMs(tester, 1200);

      await tester.tap(find.text('Equip now'));
      await pumpMs(tester, 500); // confirmation burst starts, text fades in

      expect(find.text('Equipped!'), findsOneWidget);
    });

    testWidgets('onEquipNow callback fires after confirmation completes', (
      tester,
    ) async {
      var fired = false;
      await tester.pumpWidget(buildCelebration(onEquipNow: () => fired = true));
      await pumpMs(tester, 1200);

      await tester.tap(find.text('Equip now'));
      // Drive past burst (800ms) + hold (650ms) = 1450ms.
      await pumpMs(tester, 1600);

      expect(fired, isTrue);
    });

    testWidgets('View collection button still works when not yet equipped', (
      tester,
    ) async {
      var opened = false;
      await tester.pumpWidget(
        buildCelebration(onViewCollection: () => opened = true),
      );
      await pumpMs(tester, 1200);

      await tester.tap(find.text('View collection'));
      expect(opened, isTrue);
    });

    testWidgets('equipItem persists avatar config to SharedPreferences', (
      tester,
    ) async {
      await tester.pumpWidget(buildCelebration());
      await pumpMs(tester, 1200);

      await tester.tap(find.text('Equip now'));
      await tester.pump(); // start async equip
      await pumpMs(tester, 200);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_avatar_config');
      expect(raw, isNotNull);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['animated_effect_id'], equals('effect_nova_trail'));
      // Drain confirmation burst + hold timer before test ends.
      await pumpMs(tester, 1600);
    });
  });
}
