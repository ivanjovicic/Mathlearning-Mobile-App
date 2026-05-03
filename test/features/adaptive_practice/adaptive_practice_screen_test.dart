import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/features/adaptive_practice/models/practice_answer_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_answer_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_response.dart';
import 'package:mathlearning/features/adaptive_practice/providers/adaptive_practice_provider.dart';
import 'package:mathlearning/features/adaptive_practice/screens/adaptive_practice_screen.dart';
import 'package:mathlearning/features/adaptive_practice/services/practice_session_api_service.dart';
import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/services/api_service.dart';
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

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows loading then first question', (tester) async {
    final provider = AdaptivePracticeProvider(
      apiService: _FakePracticeApiService(),
      learningMapRefresher: _FakeMapRefresher(),
    );

    await tester.pumpWidget(_wrap(provider, plan));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
    expect(find.text('3 + 2 = ?'), findsOneWidget);
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
    expect(find.text('4 + 4 = ?'), findsOneWidget);
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
}
