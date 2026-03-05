import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_answer_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_answer_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_difficulty.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_response.dart';
import 'package:mathlearning/features/adaptive_practice/providers/adaptive_practice_provider.dart';
import 'package:mathlearning/features/adaptive_practice/services/practice_session_api_service.dart';
import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePracticeSessionApiService extends PracticeSessionApiService {
  _FakePracticeSessionApiService() : super(apiService: ApiService());

  int answerCalls = 0;

  @override
  Future<ApiResult<PracticeStartResponse>> startSession(
    PracticeStartRequest request,
  ) async {
    return ApiResult(
      data: PracticeStartResponse.fromJson({
        'sessionId': 'session-1',
        'skillNodeId': request.skillNodeId,
        'recommendedDifficulty': request.preferredDifficulty.apiValue,
        'initialMastery': 0.32,
        'question': {
          'id': 1,
          'prompt': '1 + 1 = ?',
          'options': ['1', '2', '3', '4'],
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
          'masteryBefore': 0.32,
          'masteryAfter': 0.36,
          'xpEarned': 8,
          'nextQuestion': {
            'id': 2,
            'prompt': '2 + 2 = ?',
            'options': ['2', '3', '4', '5'],
            'difficulty': 'easy',
          },
        }),
      );
    }

    return ApiResult(
      data: PracticeAnswerResponse.fromJson({
        'isCorrect': false,
        'feedback': 'Try again',
        'masteryBefore': 0.36,
        'masteryAfter': 0.35,
        'xpEarned': 0,
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
        'correctAnswers': 1,
        'accuracy': 0.5,
        'xpEarned': 18,
        'initialMastery': 0.32,
        'finalMastery': 0.35,
        'masteryDelta': 0.03,
        'weakTopicsUpdated': true,
        'recommendedNextSkillNodeId': 'fraction_addition',
      }),
    );
  }
}

class _FakeMapRefresher implements AdaptiveLearningMapRefresher {
  int completeCalls = 0;
  int refreshCalls = 0;

  @override
  Future<void> completePractice({
    required PracticeLaunchPlan plan,
    required int xpEarned,
    required double masteryDelta,
    required double accuracy,
    required String? recommendedNextNodeId,
  }) async {
    completeCalls += 1;
  }

  @override
  Future<void> refresh(String userId) async {
    refreshCalls += 1;
  }
}

void main() {
  group('AdaptivePracticeProvider', () {
    late _FakePracticeSessionApiService apiService;
    late _FakeMapRefresher mapRefresher;
    late AdaptivePracticeProvider provider;

    const plan = PracticeLaunchPlan(
      userId: 'user-1',
      nodeId: 'fractions_basics',
      skillTitle: 'Fractions Basics',
      topicId: 4,
      subtopicId: 12,
      difficulty: SkillDifficulty.easy,
      source: PracticeSource.recent,
      practiceId: 'fractions_pack_1',
      targetQuestions: 2,
    );

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      apiService = _FakePracticeSessionApiService();
      mapRefresher = _FakeMapRefresher();
      provider = AdaptivePracticeProvider(
        apiService: apiService,
        learningMapRefresher: mapRefresher,
      );
    });

    test('start -> answer -> next -> complete flow updates state', () async {
      await provider.start(plan);

      expect(provider.sessionId, 'session-1');
      expect(provider.currentQuestion?.id, 1);
      expect(provider.targetQuestions, 2);

      await provider.answer('2');
      expect(provider.questionIndex, 1);
      expect(provider.correctCount, 1);
      expect(provider.currentQuestion?.id, 2);

      await provider.answer('3');
      expect(provider.isComplete, isTrue);
      expect(provider.completion?.sessionId, 'session-1');
      expect(provider.totalXp, 18);
      expect(mapRefresher.completeCalls, 1);
      expect(mapRefresher.refreshCalls, 1);
    });
  });
}
