import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/badge_provider.dart' show BadgeProvider, AppBadge;

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = Provider.of<BadgeProvider>(context).badges;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "🏅 Bedževi",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: badges.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: .85,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (context, index) {
          final badge = badges[index];
          return _buildBadgeCard(badge);
        },
      ),
    );
  }

  Widget _buildBadgeCard(AppBadge badge) {
    bool unlocked = badge.unlocked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            unlocked ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? Colors.greenAccent.shade400
              : Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.icon,
            style: const TextStyle(fontSize: 46),
          ),
          const SizedBox(height: 10),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: unlocked
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          // Progress circle
          SizedBox(
            width: 65,
            height: 65,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: badge.progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    unlocked ? Colors.greenAccent : Colors.white.withValues(alpha: 0.3),
                  ),
                  strokeWidth: 6,
                ),
                Icon(
                  unlocked ? Icons.check_circle : Icons.lock,
                  color:
                      unlocked ? Colors.greenAccent : Colors.white.withValues(alpha: 0.4),
                  size: 28,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
