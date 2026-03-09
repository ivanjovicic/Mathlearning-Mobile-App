import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';

class LearningMapSkeleton extends StatelessWidget {
  const LearningMapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    return ListView.builder(
      key: const Key('learning_map_skeleton'),
      padding: EdgeInsets.fromLTRB(
        spacing.m,
        spacing.m + spacing.xs,
        spacing.m,
        AppScale.s(120),
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final alignment = switch (index % 3) {
          0 => Alignment.centerLeft,
          1 => Alignment.center,
          _ => Alignment.centerRight,
        };

        return Column(
              children: [
                Align(
                  alignment: alignment,
                  child: Container(
                    width: AppScale.s(120),
                    height: AppScale.s(120),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(height: spacing.m),
              ],
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: context.motion.slow + context.motion.fast,
              color: colorScheme.surface.withValues(alpha: 0.4),
            );
      },
    );
  }
}
