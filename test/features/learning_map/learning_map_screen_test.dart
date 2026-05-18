import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/navigation/app_routes.dart';
import 'package:mathlearning/features/learning_map/models/practice_recommendation.dart';
import 'package:mathlearning/features/learning_map/models/skill_mastery.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/features/learning_map/screens/learning_map_screen.dart';
import 'package:mathlearning/features/learning_map/services/learning_map_service.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fakes.dart';

class _FakeLearningMapSource implements LearningMapDataSource {
  _FakeLearningMapSource({
    this.delay = Duration.zero,
    this.withLockedNode = false,
  });

  final Duration delay;
  final bool withLockedNode;

  @override
  Future<ApiResult<AdaptiveLearningPath>> fetchPath(String userId) async {
    await Future<void>.delayed(delay);
    return ApiResult(
      data: AdaptiveLearningPath.fromJson({
        'nodes': [
          {
            'id': 'n1',
            'title': 'Fractions Basics',
            'topicId': 4,
            'subtopicId': 12,
            'mastery': 0.32,
            'isLocked': false,
            'recommendedDifficulty': 'easy',
          },
          if (withLockedNode)
            {
              'id': 'n2',
              'title': 'Fraction Addition',
              'topicId': 4,
              'subtopicId': 13,
              'mastery': 0.18,
              'isLocked': true,
              'recommendedDifficulty': 'easy',
            },
        ],
        'edges': [
          {'from': 'n1', 'to': 'n2'},
        ],
        'recommendedNext': 'n1',
        'generatedAt': '2026-03-05T10:00:00Z',
      }),
    );
  }

  @override
  Future<ApiResult<List<SkillMastery>>> fetchMastery(String userId) async {
    await Future<void>.delayed(delay);
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
    await Future<void>.delayed(delay);
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
    await Future<void>.delayed(delay);
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

class _PracticeRouteProbe extends StatelessWidget {
  const _PracticeRouteProbe({required this.plan});

  final PracticeLaunchPlan plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('practice:${plan.nodeId}:${plan.practiceId}'));
  }
}

Widget _buildTestShell({
  required Widget child,
  required LearningMapProvider provider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => TestAuthProvider()),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
      ),
      ChangeNotifierProvider<ProgressProvider>(
        create: (_) => ProgressProvider(),
      ),
      ChangeNotifierProvider<DailyRunProvider>(
        create: (_) => DailyRunProvider(),
      ),
      ChangeNotifierProvider<LearningMapProvider>.value(value: provider),
    ],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'settings_language_code': 'en',
    });
  });

  testWidgets('LearningMapScreen shows skeleton then nodes', (tester) async {
    final provider = LearningMapProvider(
      service: _FakeLearningMapSource(delay: const Duration(milliseconds: 40)),
    );

    await tester.pumpWidget(
      _buildTestShell(
        provider: provider,
        child: const LearningMapScreen(userId: 'user-1'),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('learning_map_skeleton')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    expect(find.text('Your Daily Run is ready'), findsOneWidget);
    expect(find.byKey(const Key('daily_run_start_button')), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skill_node_n1')), findsOneWidget);
  });

  testWidgets('Node states render lock and recommended labels', (tester) async {
    final provider = LearningMapProvider(
      service: _FakeLearningMapSource(withLockedNode: true),
    );

    await tester.pumpWidget(
      _buildTestShell(
        provider: provider,
        child: const LearningMapScreen(userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('Play'), findsWidgets);
  });

  testWidgets('Tapping practice CTA routes to adaptive practice', (
    tester,
  ) async {
    final provider = LearningMapProvider(service: _FakeLearningMapSource());
    final router = GoRouter(
      initialLocation: '/learning-map',
      routes: [
        GoRoute(
          path: '/learning-map',
          builder: (context, state) =>
              const LearningMapScreen(userId: 'user-1'),
        ),
        GoRoute(
          path: '/practice/adaptive',
          builder: (_, state) {
            final plan = AdaptivePracticeRoute.fromState(state).plan;
            return _PracticeRouteProbe(plan: plan);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => TestAuthProvider(),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<ProgressProvider>(
            create: (_) => ProgressProvider(),
          ),
          ChangeNotifierProvider<DailyRunProvider>(
            create: (_) => DailyRunProvider(),
          ),
          ChangeNotifierProvider<LearningMapProvider>.value(value: provider),
        ],
        child: MaterialApp.router(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('practice_next_button')),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('practice:n1:fractions_pack_1'), findsOneWidget);
  });
}
