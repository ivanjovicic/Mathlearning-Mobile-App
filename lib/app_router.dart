import 'package:go_router/go_router.dart';

// Shell
import 'ui/app_shell.dart';

// Auth / error screens (no shell)
import 'screens/error_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/quiz_summary_screen.dart';
import 'screens/reward_screen.dart';

// Home branch
import 'screens/dashboard_screen.dart';
import 'screens/daily_review_screen.dart';
import 'screens/heatmap_screen.dart';

// Practice branch
import 'screens/adaptive_practice_screen.dart';
import 'screens/quiz_screen.dart';
import 'features/adaptive_practice/screens/adaptive_practice_screen.dart'
    as adaptive_practice;
import 'features/learning_map/models/practice_launch_plan.dart';

// Learn branch
import 'features/learning_map/screens/learning_map_screen.dart';
import 'screens/learning_path_screen.dart';
import 'screens/learning_insights_screen.dart';

// Ranks branch
import 'screens/leaderboard_screen.dart';
import 'screens/school_leaderboard_screen.dart';

// Profile branch
import 'screens/profile_screen.dart';
import 'screens/avatar_customization_screen.dart';
import 'screens/badge_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/my_feedback_screen.dart';
import 'theme_selector_page.dart';

import 'state/auth_provider.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/home',
      refreshListenable: authProvider,
      errorBuilder: (context, state) => ErrorScreen(
        location: state.location,
        error: state.error,
      ),
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
        // ── No-shell routes ────────────────────────────────────────────
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
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
          path: '/reward',
          builder: (context, state) => const RewardScreen(),
        ),
        // Top-level quiz route (no shell nav bar — full-screen experience)
        GoRoute(
          path: '/quiz',
          builder: (context, state) {
            final topicId = state.extra is int ? state.extra as int : null;
            return QuizScreen(topicId: topicId);
          },
        ),

        // ── Shell (5-tab StatefulShellRoute) ───────────────────────────
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            // ── Home branch ──────────────────────────────────────────
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const DashboardScreen(),
                  routes: [
                    GoRoute(
                      path: 'daily-review',
                      builder: (context, state) => const DailyReviewScreen(),
                    ),
                    GoRoute(
                      path: 'heatmap',
                      builder: (context, state) => const HeatmapScreen(),
                    ),
                  ],
                ),
              ],
            ),

            // ── Practice branch ───────────────────────────────────────
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/practice',
                  builder: (context, state) => const AdaptivePracticeScreen(),
                  routes: [
                    GoRoute(
                      path: 'quiz',
                      builder: (context, state) {
                        final topicId =
                            state.extra is int ? state.extra as int : null;
                        return QuizScreen(topicId: topicId);
                      },
                    ),
                    GoRoute(
                      path: 'adaptive',
                      builder: (context, state) {
                        final plan = state.extra;
                        if (plan is PracticeLaunchPlan) {
                          return adaptive_practice.AdaptivePracticeScreen(
                            plan: plan,
                          );
                        }
                        return const AdaptivePracticeScreen();
                      },
                    ),
                    GoRoute(
                      path: 'topic/:topicId',
                      builder: (context, state) {
                        final topicId =
                            int.tryParse(
                              state.pathParameters['topicId'] ?? '',
                            );
                        return QuizScreen(topicId: topicId);
                      },
                    ),
                    GoRoute(
                      path: 'daily-review',
                      builder: (context, state) =>
                          const DailyReviewScreen(),
                    ),
                  ],
                ),
              ],
            ),

            // ── Learn branch ──────────────────────────────────────────
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/learn',
                  builder: (context, state) {
                    final userId = authProvider.userId ?? 'me';
                    final focusNodeId =
                        state.queryParameters['focus'];
                    return LearningMapScreen(
                      userId: userId,
                      focusNodeId: focusNodeId,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'path',
                      builder: (context, state) =>
                          const LearningPathScreen(),
                    ),
                    GoRoute(
                      path: 'insights',
                      builder: (context, state) =>
                          const LearningInsightsScreen(),
                    ),
                  ],
                ),
              ],
            ),

            // ── Ranks branch ──────────────────────────────────────────
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/ranks',
                  builder: (context, state) => const LeaderboardScreen(),
                  routes: [
                    GoRoute(
                      path: 'school',
                      builder: (context, state) =>
                          const SchoolLeaderboardScreen(),
                    ),
                  ],
                ),
              ],
            ),

            // ── Profile branch ────────────────────────────────────────
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'avatar',
                      builder: (context, state) =>
                          const AvatarCustomizationScreen(),
                    ),
                    GoRoute(
                      path: 'badges',
                      builder: (context, state) => const BadgesScreen(),
                    ),
                    GoRoute(
                      path: 'settings',
                      builder: (context, state) => const SettingsScreen(),
                    ),
                    GoRoute(
                      path: 'themes',
                      builder: (context, state) => const ThemeSelectorPage(),
                    ),
                    GoRoute(
                      path: 'feedback',
                      builder: (context, state) => const MyFeedbackScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
