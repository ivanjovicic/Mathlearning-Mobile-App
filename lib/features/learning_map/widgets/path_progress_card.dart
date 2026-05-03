import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';
import 'package:mathlearning/widgets/ui/app_card.dart';
import 'package:mathlearning/widgets/ui/app_progress_bar.dart';

class PathProgressCard extends StatelessWidget {
  const PathProgressCard({super.key, required this.nodes});

  final List<SkillNode> nodes;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    final mastered = nodes.where((n) => n.mastery01 >= 0.8).length;
    final total = nodes.length;
    final progress = mastered / total;
    final avgMastery =
        nodes.fold(0.0, (s, n) => s + n.mastery01) / total;

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final spacing = context.spacing;
    final learningTheme = context.learningTheme;

    return AppCard(
      padding: EdgeInsets.all(spacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route_rounded,
                size: AppScale.icon(18, min: 16, max: 22),
                color: cs.primary,
              ),
              SizedBox(width: spacing.xs + spacing.xs / 2),
              Text(
                'Your Journey So Far',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.s,
                  vertical: spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(context.radius.pill),
                ),
                child: Text(
                  '$mastered / $total skills unlocked',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.s),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => AppProgressBar(
              value: value,
              height: AppScale.s(10),
              foregroundColor: learningTheme.masteryStrong,
            ),
          ),
          SizedBox(height: spacing.xs + spacing.xs / 2),
          Row(
            children: [
              Text(
                '${(progress * 100).round()}% of the map explored! 🗺️',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Avg strength: ${(avgMastery * 100).round()}%',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .slideY(begin: 0.06, duration: 320.ms, curve: Curves.easeOut);
  }
}
