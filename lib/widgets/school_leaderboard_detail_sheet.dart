import 'package:flutter/material.dart';

import '../models/school_leaderboard_models.dart';

class SchoolLeaderboardDetailSheet extends StatelessWidget {
  const SchoolLeaderboardDetailSheet({
    super.key,
    required this.school,
    this.history = const [],
  });

  final SchoolAggregateItem school;
  final List<SchoolLeaderboardHistoryPoint> history;

  static Future<void> show(
    BuildContext context, {
    required SchoolAggregateItem school,
    List<SchoolLeaderboardHistoryPoint> history = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          SchoolLeaderboardDetailSheet(school: school, history: history),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              school.schoolName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, '#${school.rank}'),
                _chip(context, '${school.score} XP'),
                if (school.weightedScore != null)
                  _chip(
                    context,
                    '${school.weightedScore!.toStringAsFixed(1)} weighted',
                  ),
                if (school.averageXp != null)
                  _chip(
                    context,
                    '${school.averageXp!.toStringAsFixed(1)} avg XP',
                  ),
                if (school.activeStudents != null)
                  _chip(context, '${school.activeStudents} active'),
                if (school.studentsCount != null)
                  _chip(context, '${school.studentsCount} students'),
                if (school.leagueTier != null && school.leagueTier!.isNotEmpty)
                  _chip(context, school.leagueTier!),
              ],
            ),
            if ((school.city?.isNotEmpty ?? false) ||
                (school.country?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 10),
              Text(
                [
                  if (school.city?.isNotEmpty ?? false) school.city,
                  if (school.country?.isNotEmpty ?? false) school.country,
                ].join(', '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (school.updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Updated ${_formatTimestamp(school.updatedAt!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Rank history',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (history.isEmpty)
              Text(
                'History will appear when the backend starts returning rank snapshots.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final point = history[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Rank #${point.rank}'),
                      subtitle: Text(
                        '${point.snapshotAt.toLocal()}'.split('.').first,
                      ),
                      trailing: point.weightedScore != null
                          ? Text(point.weightedScore!.toStringAsFixed(1))
                          : point.score != null
                          ? Text('${point.score}')
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} $hour:$minute';
  }
}
