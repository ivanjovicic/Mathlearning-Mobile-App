import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_recommendation.dart';
import 'package:mathlearning/features/learning_map/models/skill_mastery.dart';

void main() {
  group('Learning map models', () {
    test('AdaptiveLearningPath parses backend payload', () {
      final path = AdaptiveLearningPath.fromJson({
        'nodes': [
          {
            'id': 'fractions_basics',
            'title': 'Fractions Basics',
            'topicId': 4,
            'subtopicId': 12,
            'mastery': 0.32,
            'isLocked': false,
            'recommendedDifficulty': 'easy',
          },
        ],
        'edges': [
          {'from': 'fractions_basics', 'to': 'fraction_addition'},
        ],
        'recommendedNext': 'fractions_basics',
        'generatedAt': '2026-03-05T10:00:00Z',
      });

      expect(path.nodes, hasLength(1));
      expect(path.edges, hasLength(1));
      expect(path.recommendedNextNode?.id, 'fractions_basics');
      expect(path.nodes.first.recommendedDifficulty, SkillDifficulty.easy);
    });

    test('PracticeRecommendation applies safe defaults', () {
      final recommendation = PracticeRecommendation.fromJson({
        'topicId': 4,
        'topicName': 'Fractions',
        'reason': 'low_mastery',
      });

      expect(recommendation.recommendedDifficulty, SkillDifficulty.medium);
      expect(recommendation.practiceId, isEmpty);
      expect(recommendation.priorityScore, 0);
    });

    test('SkillMastery handles probability and percentage payloads', () {
      final asProbability = SkillMastery.fromJson({
        'topicId': 1,
        'topicName': 'Fractions',
        'masteryProbability': 0.41,
      });
      final asPercent = SkillMastery.fromJson({
        'topicId': 2,
        'topicName': 'Equations',
        'masteryProbability': 58,
      });

      expect(asProbability.mastery01, closeTo(0.41, 0.0001));
      expect(asPercent.mastery01, closeTo(0.58, 0.0001));
    });
  });
}
