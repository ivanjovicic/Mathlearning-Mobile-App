import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/path_node.dart';
import 'package:mathlearning/services/adaptive_learning_service.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/services/srs_service.dart';
import 'package:mathlearning/state/adaptive_provider.dart';

class _FakeAdaptiveLearningService extends AdaptiveLearningService {
  _FakeAdaptiveLearningService()
      : super(apiService: ApiService(), srsService: SrsService.instance);

  bool throwOnDashboard = false;

  @override
  Future<AdaptivePracticeData> fetchPracticeData() async {
    if (throwOnDashboard) throw Exception('dashboard failure');
    return AdaptivePracticeData(
      topicId: 10,
      topic: 'Algebra',
      difficulty: 'medium',
      questionCount: 8,
      confidence: 'high',
    );
  }

  @override
  Future<List<WeakTopic>> fetchWeakTopics() async {
    if (throwOnDashboard) throw Exception('dashboard failure');
    return [WeakTopic(topic: 'Fractions', accuracy: 42)];
  }

  @override
  Future<AdaptiveRecommendation> getNextRecommendation() async {
    if (throwOnDashboard) throw Exception('dashboard failure');
    return AdaptiveRecommendation(
      topicId: 10,
      topic: 'Algebra',
      difficulty: 'medium',
      questionCount: 8,
      reasoning: 'weak area',
    );
  }

  @override
  Future<AdaptiveSession> startSession({int? topicId, String? topic}) async {
    return AdaptiveSession(
      sessionId: 'session-1',
      questionIds: const [1, 2, 3],
      topic: topic ?? 'Algebra',
      difficulty: 'medium',
    );
  }

  @override
  Future<int> fetchDueReviewCount() async => 3;

  @override
  Future<AdaptivePathLoadResult> loadAdaptivePath({
    required List<Map<String, dynamic>> fallbackTopics,
    required int fallbackDueCount,
    required int userLevel,
    bool forceRefresh = false,
  }) async {
    return AdaptivePathLoadResult(
      nodes: const [
        PathNode(
          id: 'n1',
          type: PathNodeType.lesson,
          topicId: 1,
          topicName: 'Algebra',
          difficulty: DifficultyLevel.medium,
          mastery: 50,
          state: PathNodeState.available,
          confidence: ConfidenceLevel.med,
          xpReward: 25,
          estimatedMinutes: 6,
        ),
      ],
      isOfflineFallback: false,
      isCached: forceRefresh,
      isRetrying: false,
    );
  }
}

void main() {
  group('AdaptiveProvider', () {
    late _FakeAdaptiveLearningService service;
    late AdaptiveProvider provider;

    setUp(() {
      service = _FakeAdaptiveLearningService();
      provider = AdaptiveProvider(adaptiveService: service);
    });

    test('loadDashboard maps service payloads into provider state', () async {
      await provider.loadDashboard();

      expect(provider.error, isNull);
      expect(provider.practiceData?.topic, 'Algebra');
      expect(provider.weakTopics, isNotEmpty);
      expect(provider.recommendation?.reasoning, 'weak area');
    });

    test('loadDashboard sets error when service fails', () async {
      service.throwOnDashboard = true;
      await provider.loadDashboard();

      expect(provider.error, isNotNull);
      expect(provider.practiceData, isNull);
    });

    test('startSession stores adaptive session', () async {
      await provider.startSession(topicId: 1, topic: 'Algebra');

      expect(provider.adaptiveSession, isNotNull);
      expect(provider.adaptiveSession?.questionIds.length, 3);
    });

    test('loadAdaptivePath updates path flags', () async {
      await provider.loadAdaptivePath(forceRefresh: true);

      expect(provider.pathNodes, isNotEmpty);
      expect(provider.isCached, isTrue);
      expect(provider.isOfflineFallback, isFalse);
    });
  });
}
