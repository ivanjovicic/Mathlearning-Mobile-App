import 'package:flutter/material.dart';

import '../theme/app_scale.dart';
import '../theme/theme_extensions/theme_context.dart';

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: AppScale.icon(64, min: 56, max: 84),
            color: colorScheme.onSurface,
          ),
          SizedBox(height: spacing.m),
          Text(
            'Nema rezultata',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
