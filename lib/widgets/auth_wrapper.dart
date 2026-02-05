import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_i18n.dart';
import '../state/auth_provider.dart';
import '../theme/theme_controller.dart';
import '../screens/home/gamified_home_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeController>(
      builder: (context, authProvider, _, child) {
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
        return authProvider.isAuthenticated
            ? const HomeEntryScreen()
            : const LoginScreen();
      },
    );
  }
}

class HomeEntryScreen extends StatelessWidget {
  const HomeEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final useGamifiedHome = context.select<ThemeController, bool>(
      (controller) => controller.useGamifiedHome,
    );

    return useGamifiedHome
        ? const GamifiedHomeScreen()
        : const HomeScreen();
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
    // Try auto-login when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.autoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
