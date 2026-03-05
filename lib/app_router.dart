import 'package:go_router/go_router.dart';

// Screen imports for router
import 'screens/astrax_home_screen.dart';
import 'screens/daily_review_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/heatmap_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/school_leaderboard_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/badge_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'theme_selector_page.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/quiz_summary_screen.dart';
import 'screens/my_feedback_screen.dart';
import 'screens/adaptive_practice_screen.dart';
import 'screens/learning_insights_screen.dart';
import 'screens/learning_path_screen.dart';
import 'features/adaptive_practice/screens/adaptive_practice_screen.dart'
    as adaptive_practice;
import 'features/learning_map/models/practice_launch_plan.dart';
import 'features/learning_map/screens/learning_map_screen.dart';
import 'state/auth_provider.dart';
import 'widgets/auth_wrapper.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/home',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final path = state.location;
        final isLoginRoute = path == '/login';
        final isAuthenticated = authProvider.isAuthenticated;

        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }
        if (isAuthenticated && isLoginRoute) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/home'),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeEntryScreen(),
        ),
        GoRoute(
          path: '/astrax-home',
          builder: (context, state) => const AstraHomeScreen(),
        ),
        GoRoute(
          path: '/daily-review',
          builder: (context, state) => const DailyReviewScreen(),
        ),
        GoRoute(
          path: '/quiz',
          builder: (context, state) {
            final topicId = state.extra is int ? state.extra as int : null;
            return QuizScreen(topicId: topicId);
          },
        ),
        GoRoute(
          path: '/heatmap',
          builder: (context, state) => const HeatmapScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),
        GoRoute(
          path: '/school-leaderboard',
          builder: (context, state) => const SchoolLeaderboardScreen(),
        ),
        GoRoute(
          path: '/reward',
          builder: (context, state) => const RewardScreen(),
        ),
        GoRoute(
          path: '/badges',
          builder: (context, state) => const BadgesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/themes',
          builder: (context, state) => const ThemeSelectorPage(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/quiz-summary',
          builder: (context, state) {
            final stats = state.extra;
            if (stats is QuizSessionStats) {
              return QuizSummaryScreen.withStats(stats);
            }
            return const QuizSummaryScreen();
          },
        ),
        GoRoute(
          path: '/my-feedback',
          builder: (context, state) => const MyFeedbackScreen(),
        ),
        GoRoute(
          path: '/adaptive-practice',
          builder: (context, state) => const AdaptivePracticeScreen(),
        ),
        GoRoute(
          path: '/learning-insights',
          builder: (context, state) => const LearningInsightsScreen(),
        ),
        GoRoute(
          path: '/learning-path',
          builder: (context, state) => const LearningPathScreen(),
        ),
        GoRoute(
          path: '/learning-map',
          builder: (context, state) {
            final userId =
                (state.extra is String ? state.extra as String : null) ??
                state.queryParams['userId'] ??
                authProvider.userId ??
                'me';
            final focusNodeId = state.queryParams['focus'];
            return LearningMapScreen(userId: userId, focusNodeId: focusNodeId);
          },
        ),
        GoRoute(
          path: '/learning-map/practice',
          builder: (context, state) {
            final payload = state.extra;
            if (payload is PracticeLaunchPlan) {
              return adaptive_practice.AdaptivePracticeScreen(plan: payload);
            }
            final userId = authProvider.userId ?? 'me';
            return LearningMapScreen(userId: userId);
          },
        ),
      ],
    );
  }
}
