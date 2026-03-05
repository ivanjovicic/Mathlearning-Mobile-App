import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/path_node.dart';
import 'package:mathlearning/services/adaptive_learning_service.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/services/srs_service.dart';
import 'package:mathlearning/state/adaptive_provider.dart';
import 'package:mathlearning/state/learning_path_provider.dart';
import 'package:mathlearning/screens/learning_path_screen.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';
import 'package:mathlearning/theme/theme_controller.dart';

import '../helpers/test_app.dart';
import '../helpers/test_fakes.dart';

// ── Stub service ──────────────────────────────────────────────────────────────

class _StubAdaptiveLearningService extends AdaptiveLearningService {
  final List<PathNode> nodes;
  final int dueCount;

  _StubAdaptiveLearningService({
    required this.nodes,
    this.dueCount = 0,
  }) : super(
          apiService: ApiService(),
          srsService: SrsService.instance,
        );

  @override
  Future<int> fetchDueReviewCount() async => dueCount;

  @override
  Future<AdaptivePathLoadResult> loadAdaptivePath({
    required List<Map<String, dynamic>> fallbackTopics,
    required int fallbackDueCount,
    required int userLevel,
    bool forceRefresh = false,
  }) async {
    return AdaptivePathLoadResult(
      nodes: nodes,
      isOfflineFallback: false,
      isCached: false,
      isRetrying: false,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

List<PathNode> _makeNodes() => [
      const PathNode(
        id: 'n1',
        type: PathNodeType.review,
        topicId: 1,
        topicName: 'Algebra',
        difficulty: DifficultyLevel.easy,
        confidence: ConfidenceLevel.low,
        mastery: 30,
        state: PathNodeState.available,
        xpReward: 20,
        estimatedMinutes: 5,
        dueReviewCount: 3,
      ),
      const PathNode(
        id: 'n2',
        type: PathNodeType.lesson,
        topicId: 2,
        topicName: 'Geometry',
        difficulty: DifficultyLevel.medium,
        confidence: ConfidenceLevel.med,
        mastery: 60,
        state: PathNodeState.available,
        xpReward: 30,
        estimatedMinutes: 8,
        dueReviewCount: 0,
      ),
      const PathNode(
        id: 'n3',
        type: PathNodeType.lesson,
        topicId: 3,
        topicName: 'Calculus',
        difficulty: DifficultyLevel.hard,
        confidence: ConfidenceLevel.low,
        mastery: 0,
        state: PathNodeState.locked,
        xpReward: 40,
        estimatedMinutes: 10,
        dueReviewCount: 0,
      ),
    ];

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  // --------------------------------------------------------------------------
  // Unit tests — LearningPathProvider
  // --------------------------------------------------------------------------
  group('LearningPathProvider', () {
    late LearningPathProvider provider;
    late List<PathNode> nodes;

    setUp(() {
      nodes = _makeNodes();
      provider = LearningPathProvider(
        service: _StubAdaptiveLearningService(nodes: nodes, dueCount: 3),
      );
    });

    test('starts with empty nodes and no loading state', () {
      expect(provider.nodes, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadPath populates nodes from stub service', () async {
      await provider.loadPath();

      expect(provider.nodes, hasLength(3));
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.isOfflineFallback, isFalse);
    });

    test('recommended returns first available node', () async {
      await provider.loadPath();

      final rec = provider.recommended;
      expect(rec, isNotNull);
      expect(rec!.id, 'n1');
      expect(rec.state, PathNodeState.available);
    });

    test('recommended prefers inProgress over available', () async {
      await provider.loadPath();
      provider.markNodeStarted('n2');

      final rec = provider.recommended;
      expect(rec?.id, 'n2');
      expect(rec?.state, PathNodeState.inProgress);
    });

    test('markNodeStarted sets state to inProgress', () async {
      await provider.loadPath();
      provider.markNodeStarted('n1');

      final n1 = provider.nodes.firstWhere((n) => n.id == 'n1');
      expect(n1.state, PathNodeState.inProgress);
    });

    test('markNodeCompleted sets state and updates mastery', () async {
      await provider.loadPath();
      provider.markNodeCompleted('n2', newMastery: 85.0);

      final n2 = provider.nodes.firstWhere((n) => n.id == 'n2');
      expect(n2.state, PathNodeState.completed);
      expect(n2.mastery, 85.0);
    });

    test('markNodeCompleted on unknown id is a no-op', () async {
      await provider.loadPath();
      final before = List.of(provider.nodes);
      provider.markNodeCompleted('nonexistent');

      expect(provider.nodes.length, before.length);
    });

    test('dueReviewCount reads from first review node', () async {
      await provider.loadPath();
      // n1 is a review node with dueReviewCount: 3
      expect(provider.dueReviewCount, 3);
    });

    test('loadPath is idempotent when nodes already loaded', () async {
      await provider.loadPath();
      final firstLoad = provider.nodes;
      await provider.loadPath(); // second call — should skip

      expect(provider.nodes, same(firstLoad));
    });

    test('loadPath with forceRefresh reloads nodes', () async {
      await provider.loadPath();
      expect(provider.nodes, hasLength(3));

      // Mutate a node so we can verify the list is refreshed
      provider.markNodeCompleted('n1');
      expect(
        provider.nodes.firstWhere((n) => n.id == 'n1').state,
        PathNodeState.completed,
      );

      // forceRefresh restores the original stub data
      await provider.loadPath(forceRefresh: true);
      expect(provider.nodes, hasLength(3));
      // State should be back to the stub's original value (available)
      expect(
        provider.nodes.firstWhere((n) => n.id == 'n1').state,
        PathNodeState.available,
      );
    });
  });

  // --------------------------------------------------------------------------
  // Widget smoke tests — LearningPathScreen
  // --------------------------------------------------------------------------
  group('LearningPathScreen smoke', () {
    testWidgets('renders without crashing with empty nodes', (tester) async {
      final pathProvider = LearningPathProvider(
        service: _StubAdaptiveLearningService(nodes: const []),
      );

      await tester.pumpWidget(
        buildTestApp(
          home: const LearningPathScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => TestAuthProvider()),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider(create: (_) => TestCoinProvider()),
            ChangeNotifierProvider.value(value: pathProvider),
            ChangeNotifierProvider(
              create: (_) => AdaptiveProvider(
                adaptiveService: _StubAdaptiveLearningService(nodes: const []),
              ),
            ),
          ],
        ),
      );

      // First frame: loading skeleton (progress indicator) may show
      await tester.pump();
      // Settle: stub service returns immediately so the list should render
      await tester.pump(const Duration(milliseconds: 200));

      // The screen built without exceptions
      expect(find.byType(LearningPathScreen), findsOneWidget);
    });

    testWidgets('renders node list when nodes are loaded', (tester) async {
      final nodes = _makeNodes();
      final pathProvider = LearningPathProvider(
        service: _StubAdaptiveLearningService(nodes: nodes),
      );
      // Pre-load so the screen shows the list immediately
      await pathProvider.loadPath();

      await tester.pumpWidget(
        buildTestApp(
          home: const LearningPathScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => TestAuthProvider()),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider(create: (_) => TestCoinProvider()),
            ChangeNotifierProvider.value(value: pathProvider),
            ChangeNotifierProvider(
              create: (_) => AdaptiveProvider(
                adaptiveService: _StubAdaptiveLearningService(nodes: nodes),
              ),
            ),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      // Verify topic names appear in the path map
      expect(find.text('Algebra'), findsWidgets);
      expect(find.text('Geometry'), findsWidgets);
    });
  });
}
