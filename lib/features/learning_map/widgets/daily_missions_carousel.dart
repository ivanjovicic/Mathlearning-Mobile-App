import 'package:flutter/material.dart';

import 'package:mathlearning/features/learning_map/models/daily_mission.dart';
import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';
import 'package:mathlearning/widgets/ui/app_card.dart';
import 'package:mathlearning/widgets/ui/app_progress_bar.dart';

class DailyMissionsCarousel extends StatelessWidget {
  const DailyMissionsCarousel({super.key, required this.missions});

  final List<DailyMission> missions;

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final motion = context.motion;

    return SizedBox(
      height: AppScale.s(132),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: missions.length,
        padding: EdgeInsets.symmetric(horizontal: spacing.m),
        separatorBuilder: (_, _) => SizedBox(width: spacing.s + spacing.xs / 2),
        itemBuilder: (context, index) {
          final mission = missions[index];
          return Semantics(
            container: true,
            label:
                '${mission.title}, progress ${mission.progress} of ${mission.goal}',
            child: AnimatedContainer(
              duration: motion.normal,
              width: AppScale.s(240),
              child: AppCard(
                padding: EdgeInsets.all(spacing.s + spacing.xs + spacing.xs / 2),
                backgroundColor: mission.completed
                    ? colors.tertiaryContainer
                    : colors.surfaceContainerLow,
                borderColor: mission.completed
                    ? colors.tertiary
                    : context.colors.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          mission.completed
                              ? Icons.check_circle
                              : Icons.flag_outlined,
                          size: AppScale.icon(18, min: 16, max: 22),
                          color: mission.completed
                              ? colors.tertiary
                              : colors.primary,
                        ),
                        SizedBox(width: spacing.xs + spacing.xs / 2),
                        Expanded(
                          child: Text(
                            mission.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AppProgressBar(
                      value: mission.progress01,
                      height: AppScale.s(7),
                    ),
                    SizedBox(height: spacing.s),
                    Row(
                      children: [
                        Text(
                          '${mission.progress}/${mission.goal}',
                          style: textTheme.labelMedium,
                        ),
                        const Spacer(),
                        Text(
                          '+${mission.rewardXp} XP',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
