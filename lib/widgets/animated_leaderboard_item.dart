import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import '../models/social_cosmetic_loadout.dart';
import 'social_cosmetic_avatar.dart';

class AnimatedLeaderboardItem extends StatelessWidget {
  final LeaderboardItem item;
  final bool isCurrentUser;
  final int previousRank;
  final String? title;
  final String? subtitle;

  const AnimatedLeaderboardItem({
    super.key,
    required this.item,
    this.isCurrentUser = false,
    this.previousRank = 0,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Use only real API-provided loadout. Empty loadout = honest default.
    final loadout = item.cosmeticLoadout ?? const SocialCosmeticLoadout();

    return ListTile(
      leading: SizedBox(
        width: 88,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 16, child: Text('${item.rank}')),
            const SizedBox(width: 8),
            SocialCosmeticAvatar(
              userId: item.userId.toString(),
              displayName: item.displayName,
              avatarUrl: item.avatarUrl,
              loadout: loadout,
              size: 42,
            ),
          ],
        ),
      ),
      title: Text(title ?? item.displayName),
      subtitle: Text(subtitle ?? 'Score: ${item.score}'),
      trailing: isCurrentUser ? const Text('Ti') : null,
    );
  }
}
