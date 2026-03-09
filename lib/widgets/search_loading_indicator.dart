import 'package:flutter/material.dart';

import '../theme/theme_extensions/theme_context.dart';

class SearchLoadingIndicator extends StatelessWidget {
  const SearchLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.all(spacing.m + spacing.xs),
      child: Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
    );
  }
}
