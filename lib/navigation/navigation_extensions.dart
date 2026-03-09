import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/learning_map/models/practice_launch_plan.dart';
import '../screens/quiz_summary_screen.dart';
import 'app_routes.dart';
import 'route_parser_helpers.dart';

extension AppNavigationContext on BuildContext {
  void goHome() => const HomeRoute().go(this);

  void goDailyReview() => const DailyReviewRoute().go(this);

  void goHeatmap() => const HeatmapRoute().go(this);

  void goLearnMap({String? focusNodeId}) =>
      LearnMapRoute(focusNodeId: focusNodeId).go(this);

  void goLesson(int lessonId) => LessonRoute(lessonId: lessonId).go(this);

  void openQuiz({
    String quizSessionId = 'new',
    int? topicId,
    bool skipDailyReviewRedirect = false,
    String? source,
  }) {
    QuizRoute(
      quizSessionId: quizSessionId,
      topicId: topicId,
      skipDailyReviewRedirect: skipDailyReviewRedirect,
      source: source,
    ).go(this);
  }

  Future<T?> pushQuiz<T>({
    String quizSessionId = 'new',
    int? topicId,
    bool skipDailyReviewRedirect = false,
    String? source,
  }) {
    return QuizRoute(
      quizSessionId: quizSessionId,
      topicId: topicId,
      skipDailyReviewRedirect: skipDailyReviewRedirect,
      source: source,
    ).push<T>(this);
  }

  Future<T?> startAdaptivePractice<T>(PracticeLaunchPlan plan) {
    return AdaptivePracticeRoute(plan: plan).push<T>(this);
  }

  void openResults(
    String sessionId, {
    String? source,
    QuizSessionStats? stats,
  }) {
    QuizResultsRoute(sessionId: sessionId, source: source, stats: stats).go(this);
  }

  void openLeaderboard() => const LeaderboardRoute().go(this);

  void openSchoolLeaderboard() => const SchoolLeaderboardRoute().go(this);

  void openMyProfile() => const MyProfileRoute().go(this);

  void openUserProfile(String userId) => UserProfileRoute(userId: userId).push(this);

  void openSettings() => const SettingsRoute().go(this);

  void openThemes() => const ThemesRoute().go(this);

  void openAvatarCustomization() => const AvatarCustomizationRoute().push(this);

  void openBadges() => const BadgesRoute().go(this);

  void openFeedback() => const FeedbackRoute().go(this);

  void openAiTutor({String? topic}) => AiTutorRoute(topic: topic).go(this);

  void openParentDashboard({String? childId}) =>
      ParentDashboardRoute(childId: childId).go(this);

  void openUserSearch({String? query}) =>
      UserSearchRoute(query: query).push(this);

  void goAfterAuthSuccess() {
    final state = GoRouterState.of(this);
    final loginRoute = LoginRoute.fromState(state);
    final target = RouteParserHelpers.sanitizeContinuation(
      loginRoute.redirectTo,
      forbiddenPrefixes: const <String>{
        AppRoutePaths.splash,
        '/auth',
      },
    );
    GoRouter.of(this).go(target ?? const HomeRoute().location);
  }

  void goAfterOnboardingCompletion() {
    final state = GoRouterState.of(this);
    final onboardingRoute = OnboardingRoute.fromState(state);
    final target = RouteParserHelpers.sanitizeContinuation(
      onboardingRoute.redirectTo,
      forbiddenPrefixes: const <String>{
        AppRoutePaths.splash,
        '/auth',
        AppRoutePaths.onboarding,
      },
    );
    GoRouter.of(this).go(target ?? const HomeRoute().location);
  }
}
