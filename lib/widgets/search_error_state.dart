import 'package:flutter/material.dart';

import '../theme/theme_extensions/theme_context.dart';
import '../ui/components/app_button.dart';

class SearchErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SearchErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.all(spacing.m),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(spacing.s + spacing.xs),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          border: Border.all(color: colorScheme.error),
          borderRadius: BorderRadius.circular(context.radius.small),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            SizedBox(height: spacing.s),
            AppButton(
              label: 'Pokusaj ponovo',
              onPressed: onRetry,
              variant: AppButtonVariant.ghost,
            ),
          ],
        ),
      ),
    );
  }
}
