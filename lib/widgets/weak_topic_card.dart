import 'package:flutter/material.dart';

import '../services/adaptive_learning_service.dart';
import '../theme/theme_extensions/theme_context.dart';
import '../ui/components/app_badge.dart';
import '../ui/components/app_card.dart';
import '../ui/components/app_progress_bar.dart';

class WeakTopicCard extends StatelessWidget {
  const WeakTopicCard({super.key, required this.weakTopic});

  final WeakTopic weakTopic;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final learning = context.learningTheme;
    final accuracy = weakTopic.accuracy.clamp(0, 100).toDouble();

    return AppCard(
      margin: EdgeInsets.symmetric(vertical: spacing.s),
      borderColor: learning.weaknessHigh.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  weakTopic.topic,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AppBadge(
                label: '${accuracy.toStringAsFixed(1)}%',
                icon: Icons.trending_down,
                backgroundColor: learning.weaknessHigh.withValues(alpha: 0.16),
                foregroundColor: learning.weaknessHigh,
              ),
            ],
          ),
          SizedBox(height: spacing.s),
          Text(
            'Accuracy',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.xs),
          AppProgressBar(
            value: accuracy / 100,
            foregroundColor: learning.weaknessHigh,
          ),
        ],
      ),
    );
  }
}
