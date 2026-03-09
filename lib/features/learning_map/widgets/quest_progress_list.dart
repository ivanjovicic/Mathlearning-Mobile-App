import 'package:flutter/material.dart';

import 'package:mathlearning/features/learning_map/models/quest.dart';
import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';
import 'package:mathlearning/ui/components/app_card.dart';
import 'package:mathlearning/ui/components/app_progress_bar.dart';

class QuestProgressList extends StatelessWidget {
  const QuestProgressList({super.key, required this.quests});

  final List<Quest> quests;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.spacing;

    return Column(
      children: quests
          .map((quest) {
            return AppCard(
              margin: EdgeInsets.only(bottom: spacing.s + spacing.xs / 2),
              padding: EdgeInsets.all(spacing.s + spacing.xs + spacing.xs / 2),
              backgroundColor: colors.surfaceContainerLow,
              borderColor: context.colors.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          quest.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (quest.completed)
                        Icon(
                          Icons.celebration_outlined,
                          color: context.status.success,
                          size: AppScale.icon(18, min: 16, max: 22),
                        ),
                    ],
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    quest.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.s + spacing.xs / 2),
                  AppProgressBar(
                    value: quest.progress01,
                    height: AppScale.s(8),
                  ),
                  SizedBox(height: spacing.s),
                  Row(
                    children: [
                      Text(
                        '${quest.progress}/${quest.goal}',
                        style: textTheme.labelMedium,
                      ),
                      const Spacer(),
                      Text(
                        '+${quest.rewardXp} XP',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
