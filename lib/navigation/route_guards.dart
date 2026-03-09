import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_provider.dart';
import '../state/onboarding_provider.dart';
import 'app_routes.dart';
import 'route_parser_helpers.dart';

abstract class AppNavigationState extends ChangeNotifier {
  bool get isAuthResolved;

  bool get isAuthenticated;

  bool get isOnboardingResolved;

  bool get isOnboardingComplete;

  bool get isReady => isAuthResolved && isOnboardingResolved;
}

class ProviderNavigationState extends ChangeNotifier
    implements AppNavigationState {
  ProviderNavigationState({
    required AuthProvider authProvider,
    required OnboardingProvider onboardingProvider,
  }) : _authProvider = authProvider,
       _onboardingProvider = onboardingProvider {
    _authProvider.addListener(notifyListeners);
    _onboardingProvider.addListener(notifyListeners);
  }

  final AuthProvider _authProvider;
  final OnboardingProvider _onboardingProvider;

  @override
  bool get isAuthResolved => !_authProvider.isLoading;

  @override
  bool get isAuthenticated => _authProvider.isAuthenticated;

  @override
  bool get isOnboardingResolved => _onboardingProvider.isLoaded;

  @override
  bool get isOnboardingComplete => _onboardingProvider.isCompleted;

  @override
  bool get isReady => isAuthResolved && isOnboardingResolved;

  @override
  void dispose() {
    _authProvider.removeListener(notifyListeners);
    _onboardingProvider.removeListener(notifyListeners);
    super.dispose();
  }
}

class AppRouteGuards {
  AppRouteGuards({required this.navigationState});

  final AppNavigationState navigationState;

  static const Set<String> _authSafePrefixes = <String>{
    AppRoutePaths.splash,
    '/auth',
  };

  static const Set<String> _postAuthForbiddenPrefixes = <String>{
    AppRoutePaths.splash,
    '/auth',
    AppRoutePaths.onboarding,
  };

  static const Set<String> _shellPrefixes = <String>{
    AppRoutePaths.home,
    '/learn',
    '/leaderboard',
    '/profile',
    '/settings',
  };

  String? redirect(GoRouterState state) {
    return _redirectUri(RouteParserHelpers.locationUri(state));
  }

  String? redirectLocation(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null) return const LoginRoute().location;
    return _redirectUri(uri);
  }

  String? _redirectUri(Uri uri) {
    final path = uri.path;
    final continuation = RouteParserHelpers.sanitizeContinuation(
      RouteParserHelpers.decodeContinuation(uri.queryParameters['continue']),
      forbiddenPrefixes: _postAuthForbiddenPrefixes,
    );

    if (!navigationState.isReady) {
      if (path == AppRoutePaths.splash) return null;
      return SplashRoute(redirectTo: uri.toString()).location;
    }

    if (path == AppRoutePaths.splash) {
      if (!navigationState.isAuthenticated) {
        return LoginRoute(redirectTo: continuation).location;
      }
      if (!navigationState.isOnboardingComplete) {
        return OnboardingRoute(redirectTo: continuation).location;
      }
      return continuation ?? const HomeRoute().location;
    }

    if (!navigationState.isAuthenticated) {
      if (_isAuthSafe(path)) return null;
      return LoginRoute(redirectTo: uri.toString()).location;
    }

    if (!navigationState.isOnboardingComplete) {
      if (path == AppRoutePaths.onboarding) return null;
      final intendedDestination = _isAuthSafe(path) ? continuation : uri.toString();
      return OnboardingRoute(redirectTo: intendedDestination).location;
    }

    if (_isAuthSafe(path) || path == AppRoutePaths.onboarding) {
      return continuation ?? const HomeRoute().location;
    }

    return null;
  }

  bool isShellLocation(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null) return false;
    return _shellPrefixes.any(uri.path.startsWith);
  }

  bool _isAuthSafe(String path) {
    return _authSafePrefixes.any(path.startsWith);
  }
}
