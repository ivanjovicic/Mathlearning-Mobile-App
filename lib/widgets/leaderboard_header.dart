import 'package:flutter/material.dart';

class LeaderboardHeader extends StatelessWidget {
  const LeaderboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Leaderboard',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}