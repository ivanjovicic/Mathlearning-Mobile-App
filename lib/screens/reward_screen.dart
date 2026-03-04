import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/coin_provider.dart';
import '../state/progress_provider.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/ui/app_section.dart';

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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: RewardCard(
            xp: progress.xp,
            level: progress.level,
            badge: progress.getBadgeName(),
            coinReward: _calculateCoinReward(progress.accuracy),
            onLevelUp: () => _showLevelUpDialog(progress.level),
          ),
        ),
      ),
    );
  }

  void _showLevelUpDialog(int level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: LevelUpAnimation(
          level: level,
          onFinished: () {
            context.go('/home');
          },
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

class RewardCard extends StatelessWidget {
  final int xp;
  final int level;
  final String badge;
  final int coinReward;
  final VoidCallback onLevelUp;

  const RewardCard({
    super.key,
    required this.xp,
    required this.level,
    required this.badge,
    required this.coinReward,
    required this.onLevelUp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
          AppSection(
            title: "Nagrade",
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Column(
              children: [
                RewardDetail(
                  icon: Icons.monetization_on,
                  text: "+$coinReward zlatnika",
                  backgroundColor: colorScheme.secondaryContainer,
                  textColor: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  "+$xp XP",
                  style: TextStyle(
                    fontSize: 24,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Novi nivo: $level",
                  style: TextStyle(fontSize: 22, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                RewardDetail(
                  icon: Icons.badge,
                  text: "Bedz: $badge",
                  backgroundColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.8,
                  ),
                  textColor: colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: onLevelUp, child: const Text("Nastavi")),
        ],
      ),
    );
  }
}

class RewardDetail extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const RewardDetail({
    super.key,
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
