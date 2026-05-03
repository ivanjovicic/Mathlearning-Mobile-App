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
import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/services/api_service.dart';
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
          'prompt': 'Gate ${startCalls}.1',
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
  List<PracticeLaunchPlan> plans,
) {
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

    await tester.pumpWidget(_wrapDailyRun(provider, comboRunPlans));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('A').first);
      await tester.pump();
      await tester.tap(find.text('Clear Gate'));
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Combo x2'), findsOneWidget);
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

  testWidgets('daily chest reward sheet reveals rewards sequentially', (
    tester,
  ) async {
    const reward = DailyChestReward(
      xp: 30,
      coins: 12,
      cosmeticFragment: 'Nova Trail Fragment',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyChestRewardSheet(reward: reward, onContinue: () {}),
        ),
      ),
    );

    expect(find.text('+30 XP'), findsOneWidget);
    expect(find.text('+12 coins'), findsNothing);
    expect(find.text('Cosmetic fragment found'), findsNothing);

    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('+30 XP'), findsWidgets);
    expect(find.text('+12 coins'), findsNothing);

    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('+12 coins'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('Cosmetic fragment found'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Tomorrow\'s chest is even better 👀'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
