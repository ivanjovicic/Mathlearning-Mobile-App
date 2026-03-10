import 'package:flutter/material.dart';

import '../navigation/navigation_extensions.dart';

enum LeaderboardTabDestination { users, schools }

class LeaderboardTabs extends StatelessWidget {
  const LeaderboardTabs({super.key, required this.selected});

  final LeaderboardTabDestination selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: 'Leaderboard sections',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _LeaderboardTabChip(
                label: 'Users',
                selected: selected == LeaderboardTabDestination.users,
                onTap: context.openLeaderboard,
              ),
            ),
            Expanded(
              child: _LeaderboardTabChip(
                label: 'Schools',
                selected: selected == LeaderboardTabDestination.schools,
                onTap: context.openSchoolLeaderboard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTabChip extends StatelessWidget {
  const _LeaderboardTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Show $label leaderboard',
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selected ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: (textTheme.labelLarge ?? const TextStyle()).copyWith(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
