import 'package:flutter/material.dart';
import '../models/school_leaderboard_models.dart';

class MySchoolCard extends StatelessWidget {
  final SchoolAggregateItem? school;

  const MySchoolCard({super.key, this.school});

  @override
  Widget build(BuildContext context) {
    if (school == null) return const SizedBox.shrink();
    final item = school!;
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 8,
      color: cs.primaryContainer.withValues(alpha: 0.92),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          child: Text('${item.rank}'),
        ),
        title: Text(
          item.schoolName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onPrimaryContainer,
          ),
        ),
        subtitle: Text(
          [
            'Score: ${item.score}',
            if (item.averageXp != null)
              'Avg XP: ${item.averageXp!.toStringAsFixed(1)}',
            if (item.activeStudents != null) 'Active: ${item.activeStudents}',
          ].join(' • '),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onPrimaryContainer,
          ),
        ),
        trailing: item.rankDelta == null || item.rankDelta == 0
            ? null
            : Text(
                item.rankDelta! > 0 ? '+${item.rankDelta}' : '${item.rankDelta}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: item.rankDelta! > 0 ? Colors.green : cs.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
