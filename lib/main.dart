import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/badge_screen.dart';
import 'screens/daily_review_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/heatmap_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/settings_screen.dart';

import 'state/badge_provider.dart';
import 'state/leaderboard_provider.dart';
import 'state/auth_provider.dart';
import 'state/quiz_provider.dart';
import 'state/progress_provider.dart';
import 'state/heatmap_provider.dart';
import 'state/coin_provider.dart';
import 'state/settings_provider.dart';

import 'theme/theme_controller.dart';
import 'theme_selector_page.dart';
import 'widgets/auth_wrapper.dart';

import 'widgets/game_theme_transition.dart';
import 'effects/vertical_portal_transition.dart';
import 'effects/glass_break_transition.dart';

import 'services/offline_manager.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthService.instance.initialize();
  OfflineManager.instance.initialize();
  await NotificationService.instance.initialize();

  runApp(const MathLearningApp());
}

class MathLearningApp extends StatelessWidget {
  const MathLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => CoinProvider()),
        ChangeNotifierProxyProvider<ProgressProvider, BadgeProvider>(
          create: (context) => BadgeProvider(
            Provider.of<ProgressProvider>(context, listen: false),
          ),
          update: (context, progress, previous) => BadgeProvider(progress),
        ),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => HeatmapProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final locale = context.select<SettingsProvider, Locale>(
      (settings) => settings.locale,
    );
    final reduceMotion = themeController.reduceMotion;
    final highContrast = themeController.highContrast;
    final transitionTrigger = themeController.isSwitching && !reduceMotion;
    final transitionDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 350);

    final appContent = VerticalPortalTransition(
      trigger: transitionTrigger,
      child: AnimatedTheme(
        duration: transitionDuration,
        curve: Curves.easeInOut,
        data: themeController.currentTheme,
        child: GlassBreakTransition(
          trigger: transitionTrigger,
          child: RepaintBoundary(
            child: AnimatedSwitcher(
              duration: transitionDuration,
              switchOutCurve: Curves.easeIn,
              switchInCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                if (reduceMotion) return child;
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: MaterialApp(
                key: ValueKey(themeController.currentType),
                debugShowCheckedModeBanner: false,
                title: 'Math Learning',
                theme: themeController.currentTheme,
                locale: locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('sr'),
                  Locale('de'),
                  Locale('es'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      disableAnimations: reduceMotion,
                      highContrast: mediaQuery.highContrast || highContrast,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
                home: const AuthCheckWidget(child: AuthWrapper()),
                routes: {
                  "/home": (_) => const HomeEntryScreen(),
                  "/daily-review": (_) => const DailyReviewScreen(),
                  "/quiz": (_) => const QuizScreen(),
                  "/heatmap": (_) => const HeatmapScreen(),
                  "/leaderboard": (_) => const LeaderboardScreen(),
                  "/reward": (_) => const RewardScreen(),
                  "/badges": (_) => const BadgesScreen(),
                  "/profile": (_) => const ProfileScreen(),
                  "/settings": (_) => const SettingsScreen(),
                  "/login": (_) => const LoginScreen(),
                  "/themes": (_) => const ThemeSelectorPage(),
                },
              ),
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return appContent;
    }

    return GameThemeTransition(
      child: appContent,
    );
  }
}
