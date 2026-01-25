import 'package:flutter/material.dart';
import 'package:mathlearning/widgets/level_up_animation.dart';
import 'package:provider/provider.dart';
import '../state/progress_provider.dart';
import '../state/coin_provider.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<ProgressProvider>(context);
    final coinProvider = Provider.of<CoinProvider>(context);

    final int gainedXp = progress.xp;          // realni XP
    final int newLevel = progress.level;       // pravi level
    final String badge = progress.getBadgeName();
    
    // Calculate coin reward based on performance
    final int coinReward = _calculateCoinReward(progress.accuracy);
    
    // Award coins (this will be called once when screen is built)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      coinProvider.addCoins(coinReward);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.yellow.shade400,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🎉 Level Completed!",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Coin reward
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "+$coinReward coins",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
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
                    color: Colors.yellow.shade300,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "New Level: $newLevel",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("🏅 ", style: TextStyle(fontSize: 22)),
                      Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
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
            Navigator.of(context)
                .popUntil((route) => route.settings.name == "/home");
          },
        ),
      ),
    );
  },
  child: const Text("Nastavi"),
)
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateCoinReward(double accuracy) {
    // Base reward
    int baseReward = 3;
    
    // Accuracy bonus
    if (accuracy >= 90) {
      baseReward += 5; // Perfect accuracy bonus
    } else if (accuracy >= 75) {
      baseReward += 3; // Good accuracy bonus
    } else if (accuracy >= 50) {
      baseReward += 1; // Decent accuracy bonus
    }
    
    return baseReward;
  }
}
