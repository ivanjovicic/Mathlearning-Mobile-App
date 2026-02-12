import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'screens/quiz_summary_screen.dart';
import 'screens/my_feedback_screen.dart';
import 'screens/astrax_home_screen.dart';

import 'state/badge_provider.dart';
import 'state/leaderboard_provider.dart';
import 'state/auth_provider.dart';
import 'state/quiz_provider.dart';
import 'state/progress_provider.dart';
import 'state/heatmap_provider.dart';
import 'state/coin_provider.dart';
import 'state/settings_provider.dart';
import 'state/onboarding_provider.dart';

import 'theme/theme_controller.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme_selector_page.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/screen_wrapper.dart';

import 'widgets/game_theme_transition.dart';
import 'effects/vertical_portal_transition.dart';
import 'effects/glass_break_transition.dart';

import 'services/offline_manager.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/bug_capture_service.dart';
import 'services/bug_report_service.dart';
import 'services/route_tracker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow google_fonts to fetch from Google CDN at runtime.
  // On web the asset bundle may not contain bundled fonts, so this
  // prevents the AssetManifest.json 404 crash.
  GoogleFonts.config.allowRuntimeFetching = true;

  // On web, tell Flutter to use the CanvasKit-compatible font loader
  // and suppress asset-manifest errors for missing font files.
  if (kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains('AssetManifest') || msg.contains('Unable to load asset')) {
        debugPrint('⚠️ Suppressed web asset error: $msg');
        return;
      }
      FlutterError.presentError(details);
    };
  }

  await AuthService.instance.initialize();
  await OfflineManager.instance.initialize();
  await BugReportService.instance.syncPendingReports();
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
          update: (context, progress, previous) {
            if (previous == null) return BadgeProvider(progress);
            previous.updateProgress(progress);
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<ProgressProvider, QuizProvider>(
          create: (context) => QuizProvider(),
          update: (context, progress, previous) {
            if (previous == null) {
              return QuizProvider()..updateProgressProvider(progress);
            }
            previous.updateProgressProvider(progress);
            return previous;
          },
        ),
        ChangeNotifierProvider(create: (_) => HeatmapProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
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
                navigatorObservers: [RouteTracker.instance],
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  return MediaQuery(
                    data: mediaQuery.copyWith(
                      disableAnimations:
                          mediaQuery.disableAnimations || reduceMotion,
                      highContrast: mediaQuery.highContrast || highContrast,
                    ),
                    child: RepaintBoundary(
                      key: BugCaptureService.instance.rootBoundaryKey,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
                home: const AuthCheckWidget(child: AuthWrapper()),
                routes: {
                  "/home": (_) => const ScreenWrapper(child: HomeEntryScreen()),
                  "/astrax-home": (_) => const ScreenWrapper(child: AstraHomeScreen()),
                  "/daily-review": (_) => const ScreenWrapper(child: DailyReviewScreen()),
                  "/quiz": (_) => const ScreenWrapper(child: QuizScreen()),
                  "/heatmap": (_) => const ScreenWrapper(child: HeatmapScreen()),
                  "/leaderboard": (_) => const ScreenWrapper(child: LeaderboardScreen()),
                  "/reward": (_) => const ScreenWrapper(child: RewardScreen()),
                  "/badges": (_) => const ScreenWrapper(child: BadgesScreen()),
                  "/profile": (_) => const ScreenWrapper(child: ProfileScreen()),
                  "/settings": (_) => const ScreenWrapper(child: SettingsScreen()),
                  "/login": (_) => const ScreenWrapper(child: LoginScreen()),
                  "/themes": (_) => const ScreenWrapper(child: ThemeSelectorPage()),
                  "/onboarding": (_) => const ScreenWrapper(child: OnboardingScreen()),
                  "/quiz-summary": (_) => const ScreenWrapper(child: QuizSummaryScreen()),
                  "/my-feedback": (_) => const ScreenWrapper(child: MyFeedbackScreen()),
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
