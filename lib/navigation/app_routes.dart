import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/learning_map/models/practice_launch_plan.dart';
import '../screens/quiz_summary_screen.dart';
import 'route_parser_helpers.dart';

enum AppShellBranch { home, learn, practice, leaderboard, profile }

final class AppRoutePaths {
  const AppRoutePaths._();

  static const splash = '/splash';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const onboarding = '/onboarding';

  static const home = '/home';
  static const dailyReview = '/home/daily-review';
  static const heatmap = '/home/heatmap';

  static const learnMap = '/learn/map';
  static const learnLesson = '/learn/lesson';
  static const learnInsights = '/learn/insights';

  static const practiceHub = '/practice';
  static const practiceAdaptive = '/practice/adaptive';
  static const practiceResults = '/practice/results';

  static const quiz = '/quiz';

  static const leaderboardUsers = '/leaderboard/users';
  static const leaderboardSchools = '/leaderboard/schools';

  static const myProfile = '/profile/me';
  static const userProfile = '/profile/user';
  static const avatar = '/profile/avatar';
  static const badges = '/profile/badges';
  static const feedback = '/profile/feedback';

  static const settings = '/settings';
  static const themes = '/settings/themes';

  static const aiTutor = '/ai-tutor';
  static const parentDashboard = '/parent-dashboard';
  static const userSearch = '/user-search';
}

abstract class AppRouteInfo {
  const AppRouteInfo();

  String get name;

  String get path;

  Map<String, String?> get queryParameters => const <String, String?>{};

  Uri get uri =>
      RouteParserHelpers.buildUri(path, queryParameters: queryParameters);

  String get location => uri.toString();

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void replace(BuildContext context) => context.replace(location);
}

class SplashRoute extends AppRouteInfo {
  const SplashRoute({this.redirectTo});

  static const routeName = 'splash';
  final String? redirectTo;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.splash;

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'continue': redirectTo == null
        ? null
        : RouteParserHelpers.encodeContinuation(redirectTo!),
  };

  factory SplashRoute.fromState(GoRouterState state) {
    return SplashRoute(
      redirectTo: RouteParserHelpers.decodeContinuation(
        RouteParserHelpers.maybeQuery(state, 'continue'),
      ),
    );
  }
}

class LoginRoute extends AppRouteInfo {
  const LoginRoute({this.redirectTo});

  static const routeName = 'login';
  final String? redirectTo;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.login;

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'continue': redirectTo == null
        ? null
        : RouteParserHelpers.encodeContinuation(redirectTo!),
  };

  factory LoginRoute.fromState(GoRouterState state) {
    return LoginRoute(
      redirectTo: RouteParserHelpers.decodeContinuation(
        RouteParserHelpers.maybeQuery(state, 'continue'),
      ),
    );
  }
}

class RegisterRoute extends AppRouteInfo {
  const RegisterRoute({this.redirectTo});

  static const routeName = 'register';
  final String? redirectTo;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.register;

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'continue': redirectTo == null
        ? null
        : RouteParserHelpers.encodeContinuation(redirectTo!),
  };

  factory RegisterRoute.fromState(GoRouterState state) {
    return RegisterRoute(
      redirectTo: RouteParserHelpers.decodeContinuation(
        RouteParserHelpers.maybeQuery(state, 'continue'),
      ),
    );
  }
}

class OnboardingRoute extends AppRouteInfo {
  const OnboardingRoute({this.redirectTo});

  static const routeName = 'onboarding';
  final String? redirectTo;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.onboarding;

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'continue': redirectTo == null
        ? null
        : RouteParserHelpers.encodeContinuation(redirectTo!),
  };

  factory OnboardingRoute.fromState(GoRouterState state) {
    return OnboardingRoute(
      redirectTo: RouteParserHelpers.decodeContinuation(
        RouteParserHelpers.maybeQuery(state, 'continue'),
      ),
    );
  }
}

class HomeRoute extends AppRouteInfo {
  const HomeRoute();

  static const routeName = 'home';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.home;
}

class DailyReviewRoute extends AppRouteInfo {
  const DailyReviewRoute();

  static const routeName = 'daily-review';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.dailyReview;
}

class HeatmapRoute extends AppRouteInfo {
  const HeatmapRoute();

  static const routeName = 'heatmap';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.heatmap;
}

class LearnMapRoute extends AppRouteInfo {
  const LearnMapRoute({this.focusNodeId});

  static const routeName = 'learn-map';
  final String? focusNodeId;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.learnMap;

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'focus': focusNodeId,
  };

  factory LearnMapRoute.fromState(GoRouterState state) {
    return LearnMapRoute(
      focusNodeId: RouteParserHelpers.maybeQuery(state, 'focus'),
    );
  }
}

class LessonRoute extends AppRouteInfo {
  const LessonRoute({required this.lessonId});

  static const routeName = 'lesson';
  final int lessonId;

  @override
  String get name => routeName;

  @override
  String get path => '${AppRoutePaths.learnLesson}/$lessonId';

  factory LessonRoute.fromState(GoRouterState state) {
    return LessonRoute(
      lessonId: RouteParserHelpers.requireIntPathParam(state, 'lessonId'),
    );
  }
}

class LearningInsightsRoute extends AppRouteInfo {
  const LearningInsightsRoute();

  static const routeName = 'learning-insights';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.learnInsights;
}

class PracticeHubRoute extends AppRouteInfo {
  const PracticeHubRoute();

  static const routeName = 'practice-hub';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.practiceHub;
}

class QuizRoute extends AppRouteInfo {
  const QuizRoute({
    this.quizSessionId = _newSessionId,
    this.topicId,
    this.skipDailyReviewRedirect = false,
    this.source,
  });

  static const routeName = 'quiz';
  static const _newSessionId = 'new';

  final String quizSessionId;
  final int? topicId;
  final bool skipDailyReviewRedirect;
  final String? source;

  bool get isNewSession => quizSessionId == _newSessionId;

  @override
  String get name => routeName;

  @override
  String get path => '${AppRoutePaths.quiz}/$quizSessionId';

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'topicId': topicId?.toString(),
    'skipDailyReview': skipDailyReviewRedirect ? '1' : null,
    'source': source,
  };

  factory QuizRoute.fromState(GoRouterState state) {
    final sessionId = state.pathParameters['quizSessionId'];
    return QuizRoute(
      quizSessionId: (sessionId == null || sessionId.isEmpty)
          ? _newSessionId
          : sessionId,
      topicId: RouteParserHelpers.tryParseIntQuery(state, 'topicId'),
      skipDailyReviewRedirect: RouteParserHelpers.parseBoolQuery(
        state,
        'skipDailyReview',
      ),
      source: RouteParserHelpers.maybeQuery(state, 'source'),
    );
  }
}

class AdaptivePracticeRoute extends AppRouteInfo {
  const AdaptivePracticeRoute({required this.plan});

  static const routeName = 'adaptive-practice';
  final PracticeLaunchPlan plan;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.practiceAdaptive;

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'plan': RouteParserHelpers.encodeJsonPayload(plan.toJson()),
  };

  factory AdaptivePracticeRoute.fromState(GoRouterState state) {
    final raw = RouteParserHelpers.decodeJsonPayload(
      RouteParserHelpers.maybeQuery(state, 'plan'),
    );
    if (raw == null) {
      throw const FormatException('Adaptive practice plan is missing.');
    }
    return AdaptivePracticeRoute(plan: PracticeLaunchPlan.fromJson(raw));
  }
}

class QuizResultsRoute extends AppRouteInfo {
  const QuizResultsRoute({required this.sessionId, this.source, this.stats});

  static const routeName = 'quiz-results';

  final String sessionId;
  final String? source;
  final QuizSessionStats? stats;

  @override
  String get name => routeName;

  @override
  String get path => '${AppRoutePaths.practiceResults}/$sessionId';

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'source': source,
    'stats': stats == null
        ? null
        : RouteParserHelpers.encodeJsonPayload(stats!.toJson()),
  };

  factory QuizResultsRoute.fromState(GoRouterState state) {
    final sessionId = state.pathParameters['sessionId'];
    if (sessionId == null || sessionId.isEmpty) {
      throw const FormatException('Quiz results require a session id.');
    }

    final rawStats = RouteParserHelpers.decodeJsonPayload(
      RouteParserHelpers.maybeQuery(state, 'stats'),
    );

    return QuizResultsRoute(
      sessionId: sessionId,
      source: RouteParserHelpers.maybeQuery(state, 'source'),
      stats: rawStats == null ? null : QuizSessionStats.fromJson(rawStats),
    );
  }
}

class LeaderboardRoute extends AppRouteInfo {
  const LeaderboardRoute();

  static const routeName = 'leaderboard-users';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.leaderboardUsers;
}

class SchoolLeaderboardRoute extends AppRouteInfo {
  const SchoolLeaderboardRoute();

  static const routeName = 'leaderboard-schools';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.leaderboardSchools;
}

class MyProfileRoute extends AppRouteInfo {
  const MyProfileRoute();

  static const routeName = 'profile-me';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.myProfile;
}

class UserProfileRoute extends AppRouteInfo {
  const UserProfileRoute({required this.userId});

  static const routeName = 'profile-user';

  final String userId;

  @override
  String get name => routeName;

  @override
  String get path => '${AppRoutePaths.userProfile}/$userId';

  factory UserProfileRoute.fromState(GoRouterState state) {
    final userId = state.pathParameters['userId'];
    if (userId == null || userId.isEmpty) {
      throw const FormatException('User profile requires a user id.');
    }
    return UserProfileRoute(userId: userId);
  }
}

class AvatarCustomizationRoute extends AppRouteInfo {
  const AvatarCustomizationRoute();

  static const routeName = 'profile-avatar';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.avatar;
}

class BadgesRoute extends AppRouteInfo {
  const BadgesRoute();

  static const routeName = 'profile-badges';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.badges;
}

class FeedbackRoute extends AppRouteInfo {
  const FeedbackRoute();

  static const routeName = 'profile-feedback';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.feedback;
}

class SettingsRoute extends AppRouteInfo {
  const SettingsRoute();

  static const routeName = 'settings';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.settings;
}

class ThemesRoute extends AppRouteInfo {
  const ThemesRoute();

  static const routeName = 'themes';

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.themes;
}

class AiTutorRoute extends AppRouteInfo {
  const AiTutorRoute({this.topic});

  static const routeName = 'ai-tutor';

  final String? topic;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.aiTutor;

  @override
  Map<String, String?> get queryParameters => <String, String?>{'topic': topic};

  factory AiTutorRoute.fromState(GoRouterState state) {
    return AiTutorRoute(topic: RouteParserHelpers.maybeQuery(state, 'topic'));
  }
}

class ParentDashboardRoute extends AppRouteInfo {
  const ParentDashboardRoute({this.childId});

  static const routeName = 'parent-dashboard';

  final String? childId;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.parentDashboard;

  @override
  Map<String, String?> get queryParameters => <String, String?>{
    'childId': childId,
  };

  factory ParentDashboardRoute.fromState(GoRouterState state) {
    return ParentDashboardRoute(
      childId: RouteParserHelpers.maybeQuery(state, 'childId'),
    );
  }
}

class UserSearchRoute extends AppRouteInfo {
  const UserSearchRoute({this.query});

  static const routeName = 'user-search';

  final String? query;

  @override
  String get name => routeName;

  @override
  String get path => AppRoutePaths.userSearch;

  @override
  Map<String, String?> get queryParameters => <String, String?>{'query': query};

  factory UserSearchRoute.fromState(GoRouterState state) {
    return UserSearchRoute(
      query: RouteParserHelpers.maybeQuery(state, 'query'),
    );
  }
}
