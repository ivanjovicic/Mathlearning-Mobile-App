import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/navigation/app_routes.dart';
import 'package:mathlearning/navigation/route_guards.dart';
import 'package:mathlearning/navigation/route_parser_helpers.dart';

void main() {
  group('AppRouteGuards', () {
    test('bootstrapping redirects protected locations to splash', () {
      final guards = AppRouteGuards(
        navigationState: FakeAppNavigationState(
          isAuthResolved: false,
          isAuthenticated: false,
          isOnboardingResolved: false,
          isOnboardingComplete: false,
        ),
      );

      final redirect = guards.redirectLocation(const LearnMapRoute().location);

      expect(
        redirect,
        SplashRoute(redirectTo: const LearnMapRoute().location).location,
      );
    });

    test('unauthenticated users are redirected to login with continuation', () {
      final guards = AppRouteGuards(
        navigationState: FakeAppNavigationState(
          isAuthResolved: true,
          isAuthenticated: false,
          isOnboardingResolved: true,
          isOnboardingComplete: false,
        ),
      );

      final target = const UserSearchRoute(query: 'ana').location;
      final redirect = guards.redirectLocation(target);

      expect(redirect, LoginRoute(redirectTo: target).location);
    });

    test('authenticated users with incomplete onboarding go to onboarding', () {
      final guards = AppRouteGuards(
        navigationState: FakeAppNavigationState(
          isAuthResolved: true,
          isAuthenticated: true,
          isOnboardingResolved: true,
          isOnboardingComplete: false,
        ),
      );

      final target = const LearnMapRoute(focusNodeId: 'node-7').location;
      final redirect = guards.redirectLocation(target);

      expect(redirect, OnboardingRoute(redirectTo: target).location);
    });

    test('authenticated + onboarded users resume preserved target', () {
      final guards = AppRouteGuards(
        navigationState: FakeAppNavigationState(
          isAuthResolved: true,
          isAuthenticated: true,
          isOnboardingResolved: true,
          isOnboardingComplete: true,
        ),
      );

      final target = const SchoolLeaderboardRoute().location;
      final redirect = guards.redirectLocation(
        LoginRoute(redirectTo: target).location,
      );

      expect(redirect, target);
    });

    test('auth continuation is sanitized when it points back to auth flow', () {
      final guards = AppRouteGuards(
        navigationState: FakeAppNavigationState(
          isAuthResolved: true,
          isAuthenticated: true,
          isOnboardingResolved: true,
          isOnboardingComplete: true,
        ),
      );

      final unsafeContinuation = RouteParserHelpers.encodeContinuation(
        const LoginRoute().location,
      );

      final redirect = guards.redirectLocation(
        Uri(path: AppRoutePaths.login, queryParameters: <String, String>{
          'continue': unsafeContinuation,
        }).toString(),
      );

      expect(redirect, const HomeRoute().location);
    });
  });
}

class FakeAppNavigationState extends ChangeNotifier
    implements AppNavigationState {
  FakeAppNavigationState({
    required this.isAuthResolved,
    required this.isAuthenticated,
    required this.isOnboardingResolved,
    required this.isOnboardingComplete,
  });

  @override
  bool isAuthResolved;

  @override
  bool isAuthenticated;

  @override
  bool isOnboardingResolved;

  @override
  bool isOnboardingComplete;

  @override
  bool get isReady => isAuthResolved && isOnboardingResolved;
}
