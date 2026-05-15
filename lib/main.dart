import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'state/badge_provider.dart';
import 'state/leaderboard_provider.dart';
import 'state/auth_provider.dart';
import 'state/quiz_provider.dart';
import 'state/progress_provider.dart';
import 'state/heatmap_provider.dart';
import 'state/coin_provider.dart';
import 'state/settings_provider.dart';
import 'state/onboarding_provider.dart';
import 'state/streak_freeze_provider.dart';
import 'state/user_profile_provider.dart';
import 'state/adaptive_provider.dart';
import 'state/avatar_provider.dart';
import 'state/cosmetic_preview_provider.dart';
import 'state/learning_path_provider.dart';
import 'state/daily_run_provider.dart';
import 'state/daily_return_provider.dart';
import 'state/cosmetic_target_provider.dart';
import 'state/chase_race_provider.dart';
import 'state/player_identity_provider.dart';
import 'state/weekly_featured_provider.dart';
import 'state/season_provider.dart';
import 'state/session_coordinator.dart';
import 'features/learning_map/providers/learning_map_provider.dart';
import 'features/learning_map/services/learning_map_service.dart';

import 'theme/theme_controller.dart';
import 'theme/theme_preferences_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/bug_report_service.dart';
import 'services/notification_service.dart';
import 'services/offline_manager.dart';
import 'services/srs_service.dart';
import 'services/adaptive_learning_service.dart';
import 'navigation/app_router.dart';
import 'navigation/route_guards.dart';
import 'theme/app_scale.dart';
import 'theme/app_theme.dart';

// Singletons created once at process start — passed into providers instead
// of re-instantiating ApiService/SrsService in every proxy-provider callback.
final _apiService = ApiService();
final _adaptiveLearningService = AdaptiveLearningService(
  apiService: _apiService,
  srsService: SrsService.instance,
);

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
      if (msg.contains('AssetManifest') ||
          msg.contains('Unable to load asset')) {
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
        ChangeNotifierProvider(
          create: (_) => ThemeController(ThemePreferencesService()),
        ),
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
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(
          create: (_) => LearningMapProvider(
            service: LearningMapService(apiService: _apiService),
          ),
        ),
        ChangeNotifierProvider(create: (_) => DailyRunProvider()),
        ChangeNotifierProvider(create: (_) => CosmeticTargetProvider()),
        ChangeNotifierProvider(create: (_) => CosmeticPreviewProvider()),
        ChangeNotifierProvider(create: (_) => WeeklyFeaturedProvider()),
        ChangeNotifierProxyProvider3<
          ProgressProvider,
          StreakFreezeProvider,
          WeeklyFeaturedProvider,
          DailyReturnProvider
        >(
          create: (_) => DailyReturnProvider(),
          update: (_, progress, streakFreeze, weeklyFeatured, previous) {
            final provider = previous ?? DailyReturnProvider();
            provider.rebuild(
              progress: progress,
              streakFreeze: streakFreeze,
              weeklyFeatured: weeklyFeatured,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<ProgressProvider, AdaptiveProvider>(
          create: (_) =>
              AdaptiveProvider(adaptiveService: _adaptiveLearningService),
          update: (_, progress, previous) {
            final provider =
                previous ??
                AdaptiveProvider(adaptiveService: _adaptiveLearningService);
            provider.updateFromProgress(progress);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        ChangeNotifierProxyProvider<ProgressProvider, LearningPathProvider>(
          create: (_) =>
              LearningPathProvider(service: _adaptiveLearningService),
          update: (_, progress, previous) {
            final provider =
                previous ??
                LearningPathProvider(service: _adaptiveLearningService);
            provider.updateFromProgress(progress);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => SeasonProvider()),
        ChangeNotifierProvider(create: (_) => ChaseRaceProvider()),
        ChangeNotifierProxyProvider3<
          AvatarProvider,
          ProgressProvider,
          SeasonProvider,
          PlayerIdentityProvider
        >(
          create: (_) => PlayerIdentityProvider(),
          update: (_, avatar, progress, season, previous) {
            final provider = previous ?? PlayerIdentityProvider();
            provider.refresh(
              inventory: avatar.inventory,
              catalog: avatar.catalog,
              currentStreak: progress.streak,
              totalAttempts: progress.totalAttempts,
              seasonCompletionPercent: season.completionPercent,
              completedSeasonName: season.completionPercent >= 100
                  ? season.season?.name
                  : null,
              completedSeasonId: season.completionPercent >= 100
                  ? season.season?.seasonId
                  : null,
            );
            return provider;
          },
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final GoRouter _router;
  late final ProviderNavigationState _navigationState;
  final SessionCoordinator _sessionCoordinator = SessionCoordinator();
  bool _routerInitialized = false;
  bool _sessionWired = false;
  AuthProvider? _authProvider;
  CosmeticTargetProvider? _targetProvider;
  String? _lastChaseTargetKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      unawaited(_bootstrapApp(authProvider));
    });
  }

  Future<void> _bootstrapApp(AuthProvider authProvider) async {
    try {
      await AuthService.instance.initialize();
      await OfflineManager.instance.initialize();

      final loggedIn = await authProvider.autoLogin();
      if (loggedIn) {
        await OfflineManager.instance.syncPendingData();
        await BugReportService.instance.syncPendingReports();
      }
    } catch (error, stackTrace) {
      debugPrint('[Bootstrap] startup auth/offline sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      await NotificationService.instance.initialize();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routerInitialized) {
      _navigationState = ProviderNavigationState(
        authProvider: context.read<AuthProvider>(),
        onboardingProvider: context.read<OnboardingProvider>(),
      );
      _router = AppRouter.createRouter(navigationState: _navigationState);
      _routerInitialized = true;
    }

    if (_sessionWired) return;
    _authProvider = context.read<AuthProvider>();
    _targetProvider = context.read<CosmeticTargetProvider>();
    _authProvider!.addListener(_onAuthChanged);
    _targetProvider!.addListener(_onTargetChanged);
    _sessionWired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncSession());
      _onTargetChanged();
    });
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    _targetProvider?.removeListener(_onTargetChanged);
    _router.dispose();
    _navigationState.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    unawaited(_syncSession());
  }

  Future<void> _syncSession() async {
    if (!mounted) return;
    await _sessionCoordinator.synchronize(
      auth: context.read<AuthProvider>(),
      progress: context.read<ProgressProvider>(),
      quiz: context.read<QuizProvider>(),
      leaderboard: context.read<LeaderboardProvider>(),
      userProfile: context.read<UserProfileProvider>(),
      settings: context.read<SettingsProvider>(),
      avatar: context.read<AvatarProvider>(),
      cosmeticTarget: context.read<CosmeticTargetProvider>(),
      cosmeticPreview: context.read<CosmeticPreviewProvider>(),
      weeklyFeatured: context.read<WeeklyFeaturedProvider>(),
      dailyReturn: context.read<DailyReturnProvider>(),
      season: context.read<SeasonProvider>(),
      chaseRace: context.read<ChaseRaceProvider>(),
      playerIdentity: context.read<PlayerIdentityProvider>(),
      streakFreeze: context.read<StreakFreezeProvider>(),
      adaptive: context.read<AdaptiveProvider>(),
    );
    _onTargetChanged();
  }

  void _onTargetChanged() {
    if (!mounted) return;
    final target = context.read<CosmeticTargetProvider>().target;
    final chase = context.read<ChaseRaceProvider>();
    final targetKey = target == null
        ? ''
        : '${target.targetCosmeticItemId}|'
              '${target.targetFragmentsOwned}|'
              '${target.targetFragmentsRequired}|'
              '${target.bonusProgress}';
    if (_lastChaseTargetKey == targetKey) return;
    _lastChaseTargetKey = targetKey;
    chase.updateTarget(target);
    unawaited(chase.loadRaceForTarget(target));
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final locale = context.select<SettingsProvider, Locale>(
      (settings) => settings.locale,
    );
    final reduceMotion = themeController.reduceMotion;
    final highContrast = themeController.highContrast;

    return MaterialApp.router(
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
      routerConfig: _router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        AppScale.init(context);
        final scaledTheme = AppTheme.enhance(Theme.of(context));
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations: mediaQuery.disableAnimations || reduceMotion,
            highContrast: mediaQuery.highContrast || highContrast,
          ),
          child: Theme(
            data: scaledTheme,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
