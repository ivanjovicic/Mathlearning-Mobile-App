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
import 'screens/school_leaderboard_screen.dart';
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
import 'state/school_leaderboard_provider.dart';
import 'state/settings_provider.dart';
import 'state/onboarding_provider.dart';
import 'state/streak_freeze_provider.dart';
import 'state/user_profile_provider.dart';

import 'theme/theme_controller.dart';
import 'theme/theme_preferences_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme_selector_page.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/screen_wrapper.dart';

import 'widgets/game_theme_transition.dart';
import 'effects/vertical_portal_transition.dart';
import 'effects/glass_break_transition.dart';

import 'services/bug_capture_service.dart';
import 'services/route_tracker.dart';
import 'app_router.dart';
import 'app_scaffold.dart';

void main() {
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
        debugPrint('[WEB] Suppressed asset error: $msg');
        return;
      }
      FlutterError.presentError(details);
    };
  }

  runApp(const MathLearningApp());
}

class MathLearningApp extends StatelessWidget {
  const MathLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController(ThemePreferencesService())),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StreakFreezeProvider()..load()),
        ChangeNotifierProxyProvider<StreakFreezeProvider, ProgressProvider>(
          create: (_) => ProgressProvider(),
          update: (_, streakFreeze, previous) {
            final provider = previous ?? ProgressProvider();
            provider.updateStreakFreezeProvider(streakFreeze);
            return provider;
          },
        ),
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
        ChangeNotifierProxyProvider<AuthProvider, LeaderboardProvider>(
          create: (_) => LeaderboardProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? LeaderboardProvider();
            provider.onTokenUpdated(auth.token);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProfileProvider>(
          create: (_) => UserProfileProvider(),
          update: (context, auth, previous) {
            final provider = previous ?? UserProfileProvider();
            final userId = auth.userId;
            if (!auth.isAuthenticated || userId == null) {
              provider.lastUserId = null;
              provider.clear();
              return provider;
            }

            if (provider.lastUserId != userId) {
              provider.lastUserId = userId;
              provider.clear();
              provider.load(forceRefresh: true);
              return provider;
            }

            if (provider.profile == null && !provider.isLoading) {
              provider.load();
            } else {
              // no-op
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => SchoolLeaderboardProvider()),
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

    return MaterialApp.router(
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
      routerConfig: AppRouter.router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations:
                mediaQuery.disableAnimations || reduceMotion,
            highContrast: mediaQuery.highContrast || highContrast,
          ),
          child: AppScaffold(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
