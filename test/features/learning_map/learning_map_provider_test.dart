import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_recommendation.dart';
import 'package:mathlearning/features/learning_map/models/skill_mastery.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/features/learning_map/services/learning_map_service.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLearningMapSource implements LearningMapDataSource {
  bool fail = false;

  @override
  Future<ApiResult<AdaptiveLearningPath>> fetchPath(String userId) async {
    if (fail) {
      return ApiResult(error: ApiError(message: 'path failed'));
    }
    return ApiResult(
      data: AdaptiveLearningPath.fromJson({
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
        'edges': const [],
        'recommendedNext': 'fractions_basics',
        'generatedAt': '2026-03-05T10:00:00Z',
      }),
    );
  }

  @override
  Future<ApiResult<List<SkillMastery>>> fetchMastery(String userId) async {
    if (fail) {
      return ApiResult(error: ApiError(message: 'mastery failed'));
    }
    return ApiResult(
      data: const [
        SkillMastery(
          topicId: 4,
          topicName: 'Fractions',
          masteryProbability: 0.41,
        ),
      ],
    );
  }

  @override
  Future<ApiResult<List<PracticeRecommendation>>> fetchRecommendations(
    String userId,
  ) async {
    if (fail) {
      return ApiResult(error: ApiError(message: 'recommendations failed'));
    }
    return ApiResult(
      data: const [
        PracticeRecommendation(
          topicId: 4,
          topicName: 'Fractions',
          reason: 'low_mastery',
          priorityScore: 0.9,
          recommendedDifficulty: SkillDifficulty.medium,
          practiceId: 'fractions_pack_1',
        ),
      ],
    );
  }

  @override
  Future<ApiResult<List<SkillMastery>>> fetchWeakness(String userId) async {
    if (fail) {
      return ApiResult(error: ApiError(message: 'weakness failed'));
    }
    return ApiResult(
      data: const [
        SkillMastery(
          topicId: 4,
          topicName: 'Fractions',
          masteryProbability: 0.3,
        ),
      ],
    );
  }
}

void main() {
  group('LearningMapProvider', () {
    late _FakeLearningMapSource source;
    late LearningMapProvider provider;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      source = _FakeLearningMapSource();
      provider = LearningMapProvider(service: source);
    });

    test('loadAll transitions from loading to data', () async {
      final future = provider.loadAll('user-1');
      expect(provider.loading, isTrue);
      await future;

      expect(provider.loading, isFalse);
      expect(provider.error, isNull);
      expect(provider.path, isNotNull);
      expect(provider.mastery, isNotEmpty);
      expect(provider.recommendations, isNotEmpty);
      expect(provider.isOfflineFallback, isFalse);
    });

    test('loadAll uses cached payload when API fails', () async {
      await provider.loadAll('user-1');
      expect(provider.path, isNotNull);

      source.fail = true;
      await provider.loadAll('user-1');

      expect(provider.path, isNotNull);
      expect(provider.isOfflineFallback, isTrue);
    });

    test('loadAll returns error when API fails and no cache exists', () async {
      source.fail = true;
      await provider.loadAll('user-no-cache');

      expect(provider.path, isNull);
      expect(provider.error, isNotNull);
      expect(provider.isOfflineFallback, isFalse);
    });
  });
}
