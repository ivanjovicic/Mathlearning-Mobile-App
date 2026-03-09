import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_i18n.dart';
import '../state/auth_provider.dart';
import '../state/onboarding_provider.dart';
import '../services/auth_service.dart';
import '../services/bug_report_service.dart';
import '../services/notification_service.dart';
import '../services/offline_manager.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import 'screen_wrapper.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final t = context.t;
        // Show loading screen while checking auth status
        if (authProvider.isLoading) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    t.loading,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Navigate based on auth status
        if (!authProvider.isAuthenticated) {
          return const ScreenWrapper(child: LoginScreen());
        }

        // Show onboarding for first-time users
        final onboarding = Provider.of<OnboardingProvider>(
          context,
          listen: true,
        );
        if (!onboarding.isLoaded) {
          return const SizedBox.shrink(); // wait for prefs to load
        }
        if (!onboarding.isCompleted) {
          return const ScreenWrapper(child: OnboardingScreen());
        }

        return const ScreenWrapper(child: DashboardScreen());
      },
    );
  }
}

class AuthCheckWidget extends StatefulWidget {
  final Widget child;

  const AuthCheckWidget({super.key, required this.child});

  @override
  State<AuthCheckWidget> createState() => _AuthCheckWidgetState();
}

class _AuthCheckWidgetState extends State<AuthCheckWidget> {
  @override
  void initState() {
    super.initState();
    // Kick off startup work after first frame so the UI can paint immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load cached tokens/user + initialize HTTP client state (non-blocking).
      unawaited(AuthService.instance.initialize());

      // Start connectivity + offline queues (safe to call multiple times).
      unawaited(OfflineManager.instance.initialize());

      // Try auto-login; AuthWrapper will show its own loading UI while this runs.
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      unawaited(authProvider.autoLogin());

      // Background tasks that should never block first navigation.
      unawaited(BugReportService.instance.syncPendingReports());
      unawaited(NotificationService.instance.initialize());
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
