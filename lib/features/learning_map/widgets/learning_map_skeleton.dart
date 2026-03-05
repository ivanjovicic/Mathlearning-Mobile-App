import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LearningMapSkeleton extends StatelessWidget {
  const LearningMapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      key: const Key('learning_map_skeleton'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: const Duration(milliseconds: 1100),
              color: colorScheme.surface.withValues(alpha: 0.4),
            );
      },
    );
  }
}
