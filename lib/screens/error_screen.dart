import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Displayed when GoRouter encounters an unknown route or navigation error.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.location, this.error});

  final String? location;
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (location != null)
                Text(
                  location!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
