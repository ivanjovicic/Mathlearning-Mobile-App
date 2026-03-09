import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/user_search_controller.dart';
import '../features/adaptive_practice/screens/adaptive_practice_screen.dart'
    as adaptive_practice;
import '../features/learning_map/screens/learning_map_screen.dart';
import '../screens/adaptive_practice_screen.dart';
import '../screens/avatar_customization_screen.dart';
import '../screens/badge_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/daily_review_screen.dart';
import '../screens/error_screen.dart';
import '../screens/heatmap_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/learning_insights_screen.dart';
import '../screens/login_screen.dart';
import '../screens/mobile_registration_screen.dart';
import '../screens/my_feedback_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/quiz_summary_screen.dart';
import '../screens/school_leaderboard_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/user_search_screen.dart';
import '../state/auth_provider.dart';
import '../theme_selector_page.dart';
import '../ui/app_shell.dart';
import 'app_routes.dart';
import 'route_guards.dart';
import 'route_parser_helpers.dart';

abstract class AppRouteWidgetFactory {
  const AppRouteWidgetFactory();

  Widget buildSplash(BuildContext context, SplashRoute route);

  Widget buildLogin(BuildContext context, LoginRoute route);

  Widget buildRegister(BuildContext context, RegisterRoute route);

  Widget buildOnboarding(BuildContext context, OnboardingRoute route);

  Widget buildHome(BuildContext context, HomeRoute route);

  Widget buildDailyReview(BuildContext context, DailyReviewRoute route);

  Widget buildHeatmap(BuildContext context, HeatmapRoute route);

  Widget buildLearnMap(BuildContext context, LearnMapRoute route);

  Widget buildLesson(BuildContext context, LessonRoute route);

  Widget buildLearningInsights(
    BuildContext context,
    LearningInsightsRoute route,
  );

  Widget buildPracticeHub(BuildContext context, PracticeHubRoute route);

  Widget buildAdaptivePractice(
    BuildContext context,
    AdaptivePracticeRoute route,
  );

  Widget buildQuiz(BuildContext context, QuizRoute route);

  Widget buildQuizResults(BuildContext context, QuizResultsRoute route);

  Widget buildLeaderboard(BuildContext context, LeaderboardRoute route);

  Widget buildSchoolLeaderboard(
    BuildContext context,
    SchoolLeaderboardRoute route,
  );

  Widget buildMyProfile(BuildContext context, MyProfileRoute route);

  Widget buildUserProfile(BuildContext context, UserProfileRoute route);

  Widget buildAvatar(BuildContext context, AvatarCustomizationRoute route);

  Widget buildBadges(BuildContext context, BadgesRoute route);

  Widget buildFeedback(BuildContext context, FeedbackRoute route);

  Widget buildSettings(BuildContext context, SettingsRoute route);

  Widget buildThemes(BuildContext context, ThemesRoute route);

  Widget buildAiTutor(BuildContext context, AiTutorRoute route);

  Widget buildParentDashboard(
    BuildContext context,
    ParentDashboardRoute route,
  );

  Widget buildUserSearch(BuildContext context, UserSearchRoute route);
}

class DefaultAppRouteWidgetFactory extends AppRouteWidgetFactory {
  const DefaultAppRouteWidgetFactory();

  @override
  Widget buildSplash(BuildContext context, SplashRoute route) {
    return _BootstrapSplashScreen(redirectTo: route.redirectTo);
  }

  @override
  Widget buildLogin(BuildContext context, LoginRoute route) {
    return const LoginScreen();
  }

  @override
  Widget buildRegister(BuildContext context, RegisterRoute route) {
    return const MobileRegistrationScreen();
  }

  @override
  Widget buildOnboarding(BuildContext context, OnboardingRoute route) {
    return const OnboardingScreen();
  }

  @override
  Widget buildHome(BuildContext context, HomeRoute route) {
    return const DashboardScreen();
  }

  @override
  Widget buildDailyReview(BuildContext context, DailyReviewRoute route) {
    return const DailyReviewScreen();
  }

  @override
  Widget buildHeatmap(BuildContext context, HeatmapRoute route) {
    return const HeatmapScreen();
  }

  @override
  Widget buildLearnMap(BuildContext context, LearnMapRoute route) {
    final auth = context.read<AuthProvider>();
    return LearningMapScreen(
      userId: auth.userId ?? 'me',
      focusNodeId: route.focusNodeId,
    );
  }

  @override
  Widget buildLesson(BuildContext context, LessonRoute route) {
    return _FeaturePlaceholderScreen(
      title: 'Lesson ${route.lessonId}',
      subtitle:
          'Typed route is wired and deep-linkable. Replace this placeholder with the real lesson feature when ready.',
      icon: Icons.menu_book_rounded,
    );
  }

  @override
  Widget buildLearningInsights(
    BuildContext context,
    LearningInsightsRoute route,
  ) {
    return const LearningInsightsScreen();
  }

  @override
  Widget buildPracticeHub(BuildContext context, PracticeHubRoute route) {
    return const AdaptivePracticeScreen();
  }

  @override
  Widget buildAdaptivePractice(
    BuildContext context,
    AdaptivePracticeRoute route,
  ) {
    return adaptive_practice.AdaptivePracticeScreen(plan: route.plan);
  }

  @override
  Widget buildQuiz(BuildContext context, QuizRoute route) {
    return QuizScreen(
      topicId: route.topicId,
      skipDailyReviewRedirect: route.skipDailyReviewRedirect,
    );
  }

  @override
  Widget buildQuizResults(BuildContext context, QuizResultsRoute route) {
    return QuizSummaryScreen(
      sessionId: route.sessionId,
      source: route.source,
      initialStats: route.stats,
    );
  }

  @override
  Widget buildLeaderboard(BuildContext context, LeaderboardRoute route) {
    return const LeaderboardScreen();
  }

  @override
  Widget buildSchoolLeaderboard(
    BuildContext context,
    SchoolLeaderboardRoute route,
  ) {
    return const SchoolLeaderboardScreen();
  }

  @override
  Widget buildMyProfile(BuildContext context, MyProfileRoute route) {
    return const ProfileScreen();
  }

  @override
  Widget buildUserProfile(BuildContext context, UserProfileRoute route) {
    return UserProfileScreen(userId: route.userId);
  }

  @override
  Widget buildAvatar(BuildContext context, AvatarCustomizationRoute route) {
    return const AvatarCustomizationScreen();
  }

  @override
  Widget buildBadges(BuildContext context, BadgesRoute route) {
    return const BadgesScreen();
  }

  @override
  Widget buildFeedback(BuildContext context, FeedbackRoute route) {
    return const MyFeedbackScreen();
  }

  @override
  Widget buildSettings(BuildContext context, SettingsRoute route) {
    return const SettingsScreen();
  }

  @override
  Widget buildThemes(BuildContext context, ThemesRoute route) {
    return const ThemeSelectorPage();
  }

  @override
  Widget buildAiTutor(BuildContext context, AiTutorRoute route) {
    return _FeaturePlaceholderScreen(
      title: 'AI Tutor',
      subtitle: route.topic == null
          ? 'Conversation shell is routed and deep-linkable.'
          : 'Open AI tutor focused on "${route.topic}".',
      icon: Icons.smart_toy_outlined,
    );
  }

  @override
  Widget buildParentDashboard(
    BuildContext context,
    ParentDashboardRoute route,
  ) {
    return _FeaturePlaceholderScreen(
      title: 'Parent Dashboard',
      subtitle: route.childId == null
          ? 'Parent analytics route is ready for a future dashboard.'
          : 'Showing dashboard for child "${route.childId}".',
      icon: Icons.family_restroom_outlined,
    );
  }

  @override
  Widget buildUserSearch(BuildContext context, UserSearchRoute route) {
    return ChangeNotifierProvider<UserSearchController>(
      create: (_) {
        final controller = UserSearchController();
        if (route.query != null && route.query!.trim().isNotEmpty) {
          controller.searchController.text = route.query!;
          controller.onQueryChanged(route.query!);
        }
        return controller;
      },
      child: const UserSearchScreen(),
    );
  }
}

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root-nav');

  static final GlobalKey<NavigatorState> homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'home-nav');
  static final GlobalKey<NavigatorState> learnNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'learn-nav');
  static final GlobalKey<NavigatorState> leaderboardNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'leaderboard-nav');
  static final GlobalKey<NavigatorState> profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profile-nav');
  static final GlobalKey<NavigatorState> settingsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'settings-nav');

  static GoRouter createRouter({
    required AppNavigationState navigationState,
    AppRouteWidgetFactory widgetFactory = const DefaultAppRouteWidgetFactory(),
    Widget Function(BuildContext context, StatefulNavigationShell shell)?
        shellBuilder,
    String initialLocation = AppRoutePaths.splash,
  }) {
    final guards = AppRouteGuards(navigationState: navigationState);

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      refreshListenable: navigationState,
      errorBuilder: (context, state) => ErrorScreen(
        location: state.location,
        error: state.error,
      ),
      redirect: (_, state) => guards.redirect(state),
      routes: <RouteBase>[
        GoRoute(
          path: '/login',
          redirect: (_, state) => LoginRoute(
            redirectTo: RouteParserHelpers.decodeContinuation(
              state.queryParameters['continue'],
            ),
          ).location,
        ),
        GoRoute(
          path: '/profile',
          redirect: (_, state) => const MyProfileRoute().location,
        ),
        GoRoute(
          path: '/profile/settings',
          redirect: (_, state) => const SettingsRoute().location,
        ),
        GoRoute(
          path: '/profile/themes',
          redirect: (_, state) => const ThemesRoute().location,
        ),
        GoRoute(
          path: '/leaderboard',
          redirect: (_, state) => const LeaderboardRoute().location,
        ),
        GoRoute(
          path: '/ranks',
          redirect: (_, state) => const LeaderboardRoute().location,
        ),
        GoRoute(
          path: '/learn',
          redirect: (_, state) => LearnMapRoute(
            focusNodeId: state.queryParameters['focus'],
          ).location,
        ),
        GoRoute(
          path: '/quiz',
          redirect: (_, state) => QuizRoute(
            topicId: int.tryParse(state.queryParameters['topicId'] ?? ''),
            skipDailyReviewRedirect:
                state.queryParameters['skipDailyReview'] == '1',
            source: state.queryParameters['source'],
          ).location,
        ),
        GoRoute(
          path: AppRoutePaths.splash,
          name: SplashRoute.routeName,
          builder: (context, state) =>
              widgetFactory.buildSplash(context, SplashRoute.fromState(state)),
        ),
        GoRoute(
          path: AppRoutePaths.login,
          name: LoginRoute.routeName,
          builder: (context, state) =>
              widgetFactory.buildLogin(context, LoginRoute.fromState(state)),
        ),
        GoRoute(
          path: AppRoutePaths.register,
          name: RegisterRoute.routeName,
          builder: (context, state) => widgetFactory.buildRegister(
            context,
            RegisterRoute.fromState(state),
          ),
        ),
        GoRoute(
          path: AppRoutePaths.onboarding,
          name: OnboardingRoute.routeName,
          builder: (context, state) => widgetFactory.buildOnboarding(
            context,
            OnboardingRoute.fromState(state),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: AppRoutePaths.practiceHub,
          name: PracticeHubRoute.routeName,
          builder: (context, state) => widgetFactory.buildPracticeHub(
            context,
            const PracticeHubRoute(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: AppRoutePaths.practiceAdaptive,
          name: AdaptivePracticeRoute.routeName,
          builder: (context, state) => widgetFactory.buildAdaptivePractice(
            context,
            AdaptivePracticeRoute.fromState(state),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '${AppRoutePaths.practiceResults}/:sessionId',
          name: QuizResultsRoute.routeName,
          builder: (context, state) => widgetFactory.buildQuizResults(
            context,
            QuizResultsRoute.fromState(state),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '${AppRoutePaths.quiz}/:quizSessionId',
          name: QuizRoute.routeName,
          builder: (context, state) =>
              widgetFactory.buildQuiz(context, QuizRoute.fromState(state)),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: AppRoutePaths.aiTutor,
          name: AiTutorRoute.routeName,
          builder: (context, state) =>
              widgetFactory.buildAiTutor(context, AiTutorRoute.fromState(state)),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: AppRoutePaths.parentDashboard,
          name: ParentDashboardRoute.routeName,
          builder: (context, state) => widgetFactory.buildParentDashboard(
            context,
            ParentDashboardRoute.fromState(state),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: AppRoutePaths.userSearch,
          name: UserSearchRoute.routeName,
          builder: (context, state) => widgetFactory.buildUserSearch(
            context,
            UserSearchRoute.fromState(state),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              shellBuilder?.call(context, navigationShell) ??
              AppShell(navigationShell: navigationShell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              navigatorKey: homeNavigatorKey,
              routes: <GoRoute>[
                GoRoute(
                  path: AppRoutePaths.home,
                  name: HomeRoute.routeName,
                  builder: (context, state) => widgetFactory.buildHome(
                    context,
                    const HomeRoute(),
                  ),
                ),
                GoRoute(
                  path: AppRoutePaths.dailyReview,
                  name: DailyReviewRoute.routeName,
                  builder: (context, state) => widgetFactory.buildDailyReview(
                    context,
                    const DailyReviewRoute(),
                  ),
                ),
                GoRoute(
                  path: AppRoutePaths.heatmap,
                  name: HeatmapRoute.routeName,
                  builder: (context, state) =>
                      widgetFactory.buildHeatmap(context, const HeatmapRoute()),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: learnNavigatorKey,
              routes: <GoRoute>[
                GoRoute(
                  path: AppRoutePaths.learnMap,
                  name: LearnMapRoute.routeName,
                  builder: (context, state) => widgetFactory.buildLearnMap(
                    context,
                    LearnMapRoute.fromState(state),
                  ),
                ),
                GoRoute(
                  path: '${AppRoutePaths.learnLesson}/:lessonId',
                  name: LessonRoute.routeName,
                  builder: (context, state) => widgetFactory.buildLesson(
                    context,
                    LessonRoute.fromState(state),
                  ),
                ),
                GoRoute(
                  path: AppRoutePaths.learnInsights,
                  name: LearningInsightsRoute.routeName,
                  builder: (context, state) => widgetFactory.buildLearningInsights(
                    context,
                    const LearningInsightsRoute(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: leaderboardNavigatorKey,
              routes: <GoRoute>[
                GoRoute(
                  path: AppRoutePaths.leaderboardUsers,
                  name: LeaderboardRoute.routeName,
                  builder: (context, state) => widgetFactory.buildLeaderboard(
                    context,
                    const LeaderboardRoute(),
                  ),
                ),
                GoRoute(
                  path: AppRoutePaths.leaderboardSchools,
                  name: SchoolLeaderboardRoute.routeName,
                  builder: (context, state) =>
                      widgetFactory.buildSchoolLeaderboard(
                        context,
                        const SchoolLeaderboardRoute(),
                      ),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: profileNavigatorKey,
              routes: <GoRoute>[
                GoRoute(
                  path: AppRoutePaths.myProfile,
                  name: MyProfileRoute.routeName,
                  builder: (context, state) => widgetFactory.buildMyProfile(
                    context,
                    const MyProfileRoute(),
                  ),
                ),
                GoRoute(
                  path: '${AppRoutePaths.userProfile}/:userId',
                  name: UserProfileRoute.routeName,
                  builder: (context, state) => widgetFactory.buildUserProfile(
                    context,
                    UserProfileRoute.fromState(state),
                  ),
                ),
                GoRoute(
                  path: AppRoutePaths.avatar,
                  name: AvatarCustomizationRoute.routeName,
                  builder: (context, state) => widgetFactory.buildAvatar(
                    context,
                    const AvatarCustomizationRoute(),
                  ),
                ),
                GoRoute(
                  path: AppRoutePaths.badges,
                  name: BadgesRoute.routeName,
                  builder: (context, state) =>
                      widgetFactory.buildBadges(context, const BadgesRoute()),
                ),
                GoRoute(
                  path: AppRoutePaths.feedback,
                  name: FeedbackRoute.routeName,
                  builder: (context, state) =>
                      widgetFactory.buildFeedback(context, const FeedbackRoute()),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: settingsNavigatorKey,
              routes: <GoRoute>[
                GoRoute(
                  path: AppRoutePaths.settings,
                  name: SettingsRoute.routeName,
                  builder: (context, state) =>
                      widgetFactory.buildSettings(context, const SettingsRoute()),
                ),
                GoRoute(
                  path: AppRoutePaths.themes,
                  name: ThemesRoute.routeName,
                  builder: (context, state) =>
                      widgetFactory.buildThemes(context, const ThemesRoute()),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BootstrapSplashScreen extends StatelessWidget {
  const _BootstrapSplashScreen({this.redirectTo});

  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Preparing MathLearning…',
              style: theme.textTheme.titleMedium,
            ),
            if (redirectTo != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Restoring destination: $redirectTo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturePlaceholderScreen extends StatelessWidget {
  const _FeaturePlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 48, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
