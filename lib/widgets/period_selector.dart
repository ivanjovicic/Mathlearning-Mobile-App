import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final LeaderboardPeriod value;
  final ValueChanged<LeaderboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: LeaderboardPeriod.values
            .map((period) {
              final selected = period == value;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: 'Show ${period.semanticsLabel} leaderboard',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onChanged(period),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? colors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          style: (textTheme.labelLarge ?? const TextStyle())
                              .copyWith(
                                color: selected
                                    ? colors.onPrimary
                                    : colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                          child: Text(
                            period.label,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
