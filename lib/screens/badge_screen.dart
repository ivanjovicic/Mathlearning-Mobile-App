import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/badge_provider.dart' show AppBadge, BadgeProvider;

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = Provider.of<BadgeProvider>(context).badges;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        title: const Text(
          "Bedzevi",
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
        itemBuilder: (context, index) => _buildBadgeCard(context, badges[index]),
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, AppBadge badge) {
    final colorScheme = Theme.of(context).colorScheme;
    final unlocked = badge.unlocked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked ? colorScheme.primary : colorScheme.outline,
          width: 2,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : const [],
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
                  ? colorScheme.onSurface
                  : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 65,
            height: 65,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: badge.progress,
                  backgroundColor: colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                  valueColor: AlwaysStoppedAnimation(
                    unlocked ? colorScheme.primary : colorScheme.outline,
                  ),
                  strokeWidth: 6,
                ),
                Icon(
                  unlocked ? Icons.check_circle : Icons.lock,
                  color: unlocked ? colorScheme.primary : colorScheme.outline,
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
