import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/coin_provider.dart';
import '../state/progress_provider.dart';
import '../state/streak_freeze_provider.dart';
import '../utils/overlay_safety.dart';

class StreakFreezeShopSheet extends StatelessWidget {
  const StreakFreezeShopSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StreakFreezeShopSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer3<StreakFreezeProvider, CoinProvider, ProgressProvider>(
              builder: (context, freeze, coins, progress, _) {
                final cost = StreakFreezeProvider.costCoins;
                final canBuy = !freeze.isFull && coins.coins >= cost;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.tertiaryContainer,
                          ),
                          child: Icon(
                            Icons.ac_unit_rounded,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Streak Freeze',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: context.safeTooltip('Zatvori'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Cuva tvoj dnevni streak ako propustis jedan dan. Aktivira se automatski kada bi streak pukao.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _statChip(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Streak',
                          value: '${progress.streak}d',
                          colorScheme: colorScheme,
                          color: Colors.orange,
                        ),
                        _statChip(
                          icon: Icons.ac_unit_rounded,
                          label: 'Freeze',
                          value:
                              '${freeze.count}/${StreakFreezeProvider.maxCount}',
                          colorScheme: colorScheme,
                          color: colorScheme.tertiary,
                        ),
                        _statChip(
                          icon: Icons.monetization_on,
                          label: 'Coins',
                          value: '${coins.coins}',
                          colorScheme: colorScheme,
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.75,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              freeze.isFull
                                  ? 'Imas maksimalan broj freeze-ova.'
                                  : 'Cena: $cost zlatnika po freeze-u.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.85,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canBuy
                            ? () async {
                                final spent = coins.trySpendCoins(cost);
                                if (!spent) return;
                                await freeze.add(1);
                              }
                            : null,
                        child: Text(
                          freeze.isFull
                              ? 'Max'
                              : (coins.coins < cost
                                    ? 'Nedovoljno zlatnika'
                                    : 'Kupi ($cost)'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!reduceMotion)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Tip: drzi barem 1 freeze opremljen kad si u seriji.',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
