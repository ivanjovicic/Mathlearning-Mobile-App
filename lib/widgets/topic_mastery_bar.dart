import 'package:flutter/material.dart';

import '../theme/app_scale.dart';
import '../theme/theme_extensions/theme_context.dart';
import '../ui/components/app_card.dart';
import '../ui/components/app_progress_bar.dart';

class TopicMasteryBar extends StatelessWidget {
  final String topic;
  final double mastery;

  const TopicMasteryBar({
    super.key,
    required this.topic,
    required this.mastery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final safeMastery = mastery.clamp(0.0, 100.0);
    final spacing = context.spacing;

    return AppCard(
      margin: EdgeInsets.only(bottom: spacing.s + spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${safeMastery.toStringAsFixed(0)}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.s + spacing.xs / 2),
          AppProgressBar(
            value: safeMastery / 100,
            height: AppScale.s(8),
          ),
        ],
      ),
    );
  }
}
