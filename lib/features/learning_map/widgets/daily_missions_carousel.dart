import 'package:flutter/material.dart';

import 'package:mathlearning/features/learning_map/models/daily_mission.dart';

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

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: missions.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final mission = missions[index];
          return Semantics(
            container: true,
            label:
                '${mission.title}, progress ${mission.progress} of ${mission.goal}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 240,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: mission.completed
                    ? colors.tertiaryContainer
                    : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: mission.completed
                      ? colors.tertiary
                      : colors.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        mission.completed
                            ? Icons.check_circle
                            : Icons.flag_outlined,
                        size: 18,
                        color: mission.completed
                            ? colors.tertiary
                            : colors.primary,
                      ),
                      const SizedBox(width: 6),
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
                  LinearProgressIndicator(
                    value: mission.progress01,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 8),
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
          );
        },
      ),
    );
  }
}
