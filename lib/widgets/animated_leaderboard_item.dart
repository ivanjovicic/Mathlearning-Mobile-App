import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';

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
    return ListTile(
      title: Text(title ?? item.displayName),
      subtitle: Text(subtitle ?? 'Score: ${item.score}'),
      leading: CircleAvatar(child: Text('${item.rank}')),
      trailing: Text('${item.score} XP'),
    );
  }
}