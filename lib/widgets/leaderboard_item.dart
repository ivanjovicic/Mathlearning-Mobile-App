import 'package:flutter/material.dart';
import '../models/leaderboard_models.dart';

class LeaderboardItemWidget extends StatelessWidget {
  final LeaderboardItem? item;

  const LeaderboardItemWidget({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox.shrink();
    return ListTile(
      leading: CircleAvatar(child: Text('${item!.rank}')),
      title: Text(item!.displayName),
      subtitle: Text('Score: ${item!.score}'),
    );
  }
}

// Backwards compatible constructor-style helper used by legacy code.
Widget LeaderboardItem({dynamic item}) => LeaderboardItemWidget(item: item);
