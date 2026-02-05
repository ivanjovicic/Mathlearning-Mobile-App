import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/coin_provider.dart';
import '../state/progress_provider.dart';
import '../widgets/level_up_animation.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  bool _coinsAwarded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_coinsAwarded) return;

    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    final coinReward = _calculateCoinReward(progress.accuracy);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _coinsAwarded) return;
      coinProvider.addCoins(coinReward);
      _coinsAwarded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<ProgressProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final gainedXp = progress.xp;
    final newLevel = progress.level;
    final badge = progress.getBadgeName();
    final coinReward = _calculateCoinReward(progress.accuracy);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.secondary, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Nivo zavrsen!",
                  style: TextStyle(
                    fontSize: 28,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "+$coinReward coina",
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "+$gainedXp XP",
                  style: TextStyle(
                    fontSize: 24,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Novi nivo: $newLevel",
                  style: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Bedz: ", style: TextStyle(fontSize: 18)),
                      Text(
                        badge,
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Center(
                        child: LevelUpAnimation(
                          level: progress.level,
                          onFinished: () {
                            Navigator.of(context).popUntil(
                              (route) => route.settings.name == "/home",
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text("Nastavi"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateCoinReward(double accuracy) {
    var baseReward = 3;
    if (accuracy >= 90) {
      baseReward += 5;
    } else if (accuracy >= 75) {
      baseReward += 3;
    } else if (accuracy >= 50) {
      baseReward += 1;
    }
    return baseReward;
  }
}
