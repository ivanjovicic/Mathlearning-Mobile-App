import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/navigation/app_router.dart';
import 'package:mathlearning/navigation/app_routes.dart';
import 'package:mathlearning/navigation/route_guards.dart';
import 'package:mathlearning/navigation/route_parser_helpers.dart';
import 'package:mathlearning/screens/quiz_summary_screen.dart';

void main() {
  group('Typed route serialization', () {
    test('AdaptivePracticeRoute serializes and deserializes PracticeLaunchPlan', () {
      final route = AdaptivePracticeRoute(plan: _samplePlan());
      final uri = Uri.parse(route.location);
      final decoded = PracticeLaunchPlan.fromJson(
        RouteParserHelpers.decodeJsonPayload(uri.queryParameters['plan'])!,
      );

      expect(decoded.nodeId, 'node-42');
      expect(decoded.skillTitle, 'Fractions');
      expect(decoded.topicId, 4);
      expect(decoded.subtopicId, 12);
    });

    test('QuizResultsRoute serializes stats payload safely', () {
      final stats = QuizSessionStats(
        correct: 3,
        total: 5,
        xpEarned: 45,
        streak: 7,
        masteryProgress: 0.6,
        wrongQuestions: const <WrongQuestion>[
          WrongQuestion(
            questionId: 1,
            questionText: '2 + 2',
            userAnswer: '5',
            correctAnswer: '4',
          ),
        ],
      );
      final route = QuizResultsRoute(
        sessionId: 'session-9',
        source: 'quiz',
        stats: stats,
      );
      final uri = Uri.parse(route.location);
      final decoded = QuizSessionStats.fromJson(
        RouteParserHelpers.decodeJsonPayload(uri.queryParameters['stats'])!,
      );

      expect(decoded.correct, 3);
      expect(decoded.wrongQuestions.single.correctAnswer, '4');
    });
  });

  group('AppRouter', () {
    testWidgets('app start resolves splash -> login -> onboarding -> home', (
      tester,
    ) async {
      final navState = FakeAppNavigationState(
        isAuthResolved: false,
        isAuthenticated: false,
        isOnboardingResolved: false,
        isOnboardingComplete: false,
      );
      final router = AppRouter.createRouter(
        navigationState: navState,
        widgetFactory: const _TestWidgetFactory(),
        shellBuilder: _buildTestShell,
      );

      await tester.pumpWidget(_RouterHost(router: router));
      await tester.pump();

      expect(find.textContaining('splash'), findsOneWidget);

      navState.resolveUnauthenticated();
      await tester.pumpAndSettle();
      expect(find.textContaining('login'), findsOneWidget);

      navState.authenticate();
      await tester.pumpAndSettle();
      expect(find.textContaining('onboarding'), findsOneWidget);

      navState.completeOnboarding();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('deep link is restored after login and onboarding', (
      tester,
    ) async {
      final navState = FakeAppNavigationState.readyUnauthenticated();
      final router = AppRouter.createRouter(
        navigationState: navState,
        widgetFactory: const _TestWidgetFactory(),
        shellBuilder: _buildTestShell,
        initialLocation: const LearnMapRoute(focusNodeId: 'node-7').location,
      );

      await tester.pumpWidget(_RouterHost(router: router));
      await tester.pumpAndSettle();

      expect(find.textContaining('login:/learn/map?focus=node-7'), findsOneWidget);

      navState.authenticate();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('onboarding:/learn/map?focus=node-7'),
        findsOneWidget,
      );

      navState.completeOnboarding();
      await tester.pumpAndSettle();
      expect(find.text('learn-map:node-7'), findsOneWidget);
    });

    testWidgets('shell navigation switches between preserved branches', (
      tester,
    ) async {
      final navState = FakeAppNavigationState.readyAuthenticated();
      final router = AppRouter.createRouter(
        navigationState: navState,
        widgetFactory: const _TestWidgetFactory(),
        shellBuilder: _buildTestShell,
        initialLocation: const HomeRoute().location,
      );

      await tester.pumpWidget(_RouterHost(router: router));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);

      await tester.tap(find.text('Learn'));
      await tester.pumpAndSettle();
      expect(find.text('learn-map:-'), findsOneWidget);

      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      expect(find.text('leaderboard'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('my-profile'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('settings'), findsOneWidget);
    });

    testWidgets('adaptive practice deep link passes typed launch plan', (
      tester,
    ) async {
      final navState = FakeAppNavigationState.readyAuthenticated();
      final route = AdaptivePracticeRoute(plan: _samplePlan());
      final router = AppRouter.createRouter(
        navigationState: navState,
        widgetFactory: const _TestWidgetFactory(),
        shellBuilder: _buildTestShell,
        initialLocation: route.location,
      );

      await tester.pumpWidget(_RouterHost(router: router));
      await tester.pumpAndSettle();

      expect(find.text('adaptive:Fractions:4'), findsOneWidget);
    });

    testWidgets('results route restores typed stats payload', (tester) async {
      final navState = FakeAppNavigationState.readyAuthenticated();
      final router = AppRouter.createRouter(
        navigationState: navState,
        widgetFactory: const _TestWidgetFactory(),
        shellBuilder: _buildTestShell,
        initialLocation: QuizResultsRoute(
          sessionId: 'session-1',
          source: 'quiz',
          stats: QuizSessionStats(
            correct: 4,
            total: 5,
            xpEarned: 35,
            streak: 2,
            masteryProgress: 0.8,
            wrongQuestions: const <WrongQuestion>[],
          ),
        ).location,
      );

      await tester.pumpWidget(_RouterHost(router: router));
      await tester.pumpAndSettle();

      expect(find.text('results:session-1:quiz:4'), findsOneWidget);
    });

    testWidgets('logout resets protected navigation to login', (tester) async {
      final navState = FakeAppNavigationState.readyAuthenticated();
      final router = AppRouter.createRouter(
        navigationState: navState,
        widgetFactory: const _TestWidgetFactory(),
        shellBuilder: _buildTestShell,
        initialLocation: const HomeRoute().location,
      );

      await tester.pumpWidget(_RouterHost(router: router));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);

      navState.logout();
      await tester.pumpAndSettle();

      expect(find.textContaining('login'), findsOneWidget);
    });
  });
}

class _RouterHost extends StatelessWidget {
  const _RouterHost({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}

class _TestWidgetFactory extends AppRouteWidgetFactory {
  const _TestWidgetFactory();

  @override
  Widget buildAdaptivePractice(
    BuildContext context,
    AdaptivePracticeRoute route,
  ) {
    return Scaffold(
      body: Center(
        child: Text('adaptive:${route.plan.skillTitle}:${route.plan.topicId}'),
      ),
    );
  }

  @override
  Widget buildAiTutor(BuildContext context, AiTutorRoute route) =>
      const Scaffold(body: Center(child: Text('ai-tutor')));

  @override
  Widget buildAvatar(BuildContext context, AvatarCustomizationRoute route) =>
      const Scaffold(body: Center(child: Text('avatar')));

  @override
  Widget buildBadges(BuildContext context, BadgesRoute route) =>
      const Scaffold(body: Center(child: Text('badges')));

  @override
  Widget buildDailyReview(BuildContext context, DailyReviewRoute route) =>
      const Scaffold(body: Center(child: Text('daily-review')));

  @override
  Widget buildFeedback(BuildContext context, FeedbackRoute route) =>
      const Scaffold(body: Center(child: Text('feedback')));

  @override
  Widget buildHeatmap(BuildContext context, HeatmapRoute route) =>
      const Scaffold(body: Center(child: Text('heatmap')));

  @override
  Widget buildHome(BuildContext context, HomeRoute route) =>
      const Scaffold(body: Center(child: Text('home')));

  @override
  Widget buildLeaderboard(BuildContext context, LeaderboardRoute route) =>
      const Scaffold(body: Center(child: Text('leaderboard')));

  @override
  Widget buildLearnMap(BuildContext context, LearnMapRoute route) => Scaffold(
    body: Center(child: Text('learn-map:${route.focusNodeId ?? '-'}')),
  );

  @override
  Widget buildLearningInsights(
    BuildContext context,
    LearningInsightsRoute route,
  ) => const Scaffold(body: Center(child: Text('learning-insights')));

  @override
  Widget buildLesson(BuildContext context, LessonRoute route) =>
      Scaffold(body: Center(child: Text('lesson:${route.lessonId}')));

  @override
  Widget buildLogin(BuildContext context, LoginRoute route) => Scaffold(
    body: Center(child: Text('login:${route.redirectTo ?? '-'}')),
  );

  @override
  Widget buildMyProfile(BuildContext context, MyProfileRoute route) =>
      const Scaffold(body: Center(child: Text('my-profile')));

  @override
  Widget buildOnboarding(BuildContext context, OnboardingRoute route) => Scaffold(
    body: Center(child: Text('onboarding:${route.redirectTo ?? '-'}')),
  );

  @override
  Widget buildParentDashboard(
    BuildContext context,
    ParentDashboardRoute route,
  ) => const Scaffold(body: Center(child: Text('parent-dashboard')));

  @override
  Widget buildPracticeHub(BuildContext context, PracticeHubRoute route) =>
      const Scaffold(body: Center(child: Text('practice-hub')));

  @override
  Widget buildQuiz(BuildContext context, QuizRoute route) => Scaffold(
    body: Center(
      child: Text(
        'quiz:${route.quizSessionId}:${route.topicId ?? '-'}:${route.skipDailyReviewRedirect}',
      ),
    ),
  );

  @override
  Widget buildQuizResults(BuildContext context, QuizResultsRoute route) =>
      Scaffold(
        body: Center(
          child: Text(
            'results:${route.sessionId}:${route.source ?? '-'}:${route.stats?.correct ?? -1}',
          ),
        ),
      );

  @override
  Widget buildRegister(BuildContext context, RegisterRoute route) =>
      Scaffold(body: Center(child: Text('register:${route.redirectTo ?? '-'}')));

  @override
  Widget buildSchoolLeaderboard(
    BuildContext context,
    SchoolLeaderboardRoute route,
  ) => const Scaffold(body: Center(child: Text('school-leaderboard')));

  @override
  Widget buildSettings(BuildContext context, SettingsRoute route) =>
      const Scaffold(body: Center(child: Text('settings')));

  @override
  Widget buildSplash(BuildContext context, SplashRoute route) => Scaffold(
    body: Center(child: Text('splash:${route.redirectTo ?? '-'}')),
  );

  @override
  Widget buildThemes(BuildContext context, ThemesRoute route) =>
      const Scaffold(body: Center(child: Text('themes')));

  @override
  Widget buildUserProfile(BuildContext context, UserProfileRoute route) =>
      Scaffold(body: Center(child: Text('user-profile:${route.userId}')));

  @override
  Widget buildUserSearch(BuildContext context, UserSearchRoute route) =>
      Scaffold(body: Center(child: Text('user-search:${route.query ?? '-'}')));
}

Widget _buildTestShell(BuildContext context, StatefulNavigationShell shell) {
  return Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) => shell.goBranch(index),
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.map), label: 'Learn'),
        NavigationDestination(
          icon: Icon(Icons.emoji_events),
          label: 'Leaderboard',
        ),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  );
}

class FakeAppNavigationState extends ChangeNotifier
    implements AppNavigationState {
  FakeAppNavigationState({
    required this.isAuthResolved,
    required this.isAuthenticated,
    required this.isOnboardingResolved,
    required this.isOnboardingComplete,
  });

  factory FakeAppNavigationState.readyUnauthenticated() {
    return FakeAppNavigationState(
      isAuthResolved: true,
      isAuthenticated: false,
      isOnboardingResolved: true,
      isOnboardingComplete: false,
    );
  }

  factory FakeAppNavigationState.readyAuthenticated() {
    return FakeAppNavigationState(
      isAuthResolved: true,
      isAuthenticated: true,
      isOnboardingResolved: true,
      isOnboardingComplete: true,
    );
  }

  @override
  bool isAuthResolved;

  @override
  bool isAuthenticated;

  @override
  bool isOnboardingResolved;

  @override
  bool isOnboardingComplete;

  @override
  bool get isReady => isAuthResolved && isOnboardingResolved;

  void resolveUnauthenticated() {
    isAuthResolved = true;
    isOnboardingResolved = true;
    notifyListeners();
  }

  void authenticate() {
    isAuthenticated = true;
    notifyListeners();
  }

  void completeOnboarding() {
    isOnboardingComplete = true;
    notifyListeners();
  }

  void logout() {
    isAuthenticated = false;
    notifyListeners();
  }
}

PracticeLaunchPlan _samplePlan() {
  return PracticeLaunchPlan(
    userId: 'user-1',
    nodeId: 'node-42',
    skillTitle: 'Fractions',
    topicId: 4,
    subtopicId: 12,
    difficulty: SkillDifficulty.medium,
    source: PracticeSource.weak,
    practiceId: 'practice-1',
  );
}
