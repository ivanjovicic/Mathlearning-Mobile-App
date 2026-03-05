import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_answer_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_difficulty.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_response.dart';

void main() {
  group('Adaptive practice models', () {
    test('PracticeStartResponse parses resiliently', () {
      final response = PracticeStartResponse.fromJson({
        'sessionId': 'uuid',
        'skillNodeId': 'fractions_basics',
        'recommendedDifficulty': 'easy',
        'initialMastery': 0.32,
        'question': {
          'id': 123,
          'prompt': '2/3 + 1/3 = ?',
          'options': ['1', '2', '3', '4'],
          'difficulty': 'easy',
        },
      });

      expect(response.sessionId, 'uuid');
      expect(response.recommendedDifficulty, PracticeDifficulty.easy);
      expect(response.question?.id, 123);
      expect(response.question?.options, hasLength(4));
    });

    test('PracticeAnswerResponse allows null nextQuestion', () {
      final response = PracticeAnswerResponse.fromJson({
        'isCorrect': true,
        'feedback': 'Correct!',
        'masteryBefore': 0.32,
        'masteryAfter': 0.36,
        'xpEarned': 8,
        'nextQuestion': null,
      });

      expect(response.isCorrect, isTrue);
      expect(response.hasNextQuestion, isFalse);
      expect(response.nextQuestion, isNull);
    });

    test('PracticeCompleteResponse handles missing optional fields', () {
      final response = PracticeCompleteResponse.fromJson({
        'sessionId': 'uuid',
        'status': 'Completed',
        'answeredQuestions': 10,
        'correctAnswers': 8,
        'accuracy': 0.8,
        'xpEarned': 87,
        'initialMastery': 0.32,
        'finalMastery': 0.45,
        'masteryDelta': 0.13,
        'weakTopicsUpdated': true,
      });

      expect(response.recommendedNextSkillNodeId, isNull);
      expect(response.masteryDelta, closeTo(0.13, 0.0001));
    });
  });
}
