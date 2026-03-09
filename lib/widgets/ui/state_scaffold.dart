import 'package:flutter/material.dart';

import '../../theme/app_scale.dart';
import '../../theme/tokens/spacing_tokens.dart';

class StateScaffold extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final String? error;
  final Widget child;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  const StateScaffold({
    super.key,
    required this.isLoading,
    required this.isEmpty,
    required this.error,
    required this.child,
    this.onRetry,
    this.emptyTitle = 'Nema podataka',
    this.emptySubtitle = 'Pokusaj ponovo kasnije.',
    this.emptyIcon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: AppScale.icon(42, min: 36, max: 56),
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: AppSpacing.base),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokusaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: AppScale.icon(48, min: 40, max: 64)),
              SizedBox(height: AppSpacing.md),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}
