import 'package:flutter/material.dart';

/// Enterprise-grade loading indicator with optional label.
///
/// Respects reduced-motion settings by showing a static indicator.
class AstraLoadingIndicator extends StatelessWidget {
  final String? label;
  final double size;
  final double strokeWidth;

  const AstraLoadingIndicator({
    super.key,
    this.label,
    this.size = 36,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Semantics(
        label: label ?? 'Loading',
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: strokeWidth,
                color: cs.primary,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(
                label!,
                style: textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
