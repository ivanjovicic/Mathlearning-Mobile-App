import 'package:flutter/material.dart';
import '../models/leaderboard_models.dart';
import '../models/school_leaderboard_models.dart' show SchoolAggregateItem;

class LeaderboardItemWidget extends StatelessWidget {
  final dynamic item;

  const LeaderboardItemWidget({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox.shrink();

    if (item is LeaderboardItem) {
      final it = item as LeaderboardItem;
      return ListTile(
        leading: CircleAvatar(child: Text('${it.rank}')),
        title: Text(it.displayName),
        subtitle: Text('Score: ${it.score}'),
      );
    }

    if (item is SchoolAggregateItem) {
      final s = item as SchoolAggregateItem;
      return ListTile(
        leading: CircleAvatar(child: Text('${s.rank}')),
        title: Text(s.schoolName),
        subtitle: Text('Score: ${s.score}'),
      );
    }

    // Fallback: try to display minimal info
    return ListTile(
      title: Text(item.toString()),
    );
  }
}

// Backwards compatible constructor-style helper used by legacy code.
Widget LeaderboardItemWidgetFactory({dynamic item}) => LeaderboardItemWidget(item: item);
