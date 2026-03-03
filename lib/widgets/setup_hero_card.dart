import 'package:flutter/material.dart';

class SetupHeroCard extends StatelessWidget {
  final int completedGoals;
  final double completionProgress;
  final int setupXp;
  final int level;

  const SetupHeroCard({
    super.key,
    this.completedGoals = 0,
    this.completionProgress = 0.0,
    this.setupXp = 0,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('$level')),
        title: Text('Setup progress'),
        subtitle: Text('Completed: $completedGoals'),
      ),
    );
  }
}

Widget SetupHeroCardFactory({int completedGoals = 0, double completionProgress = 0.0, int setupXp = 0, int level = 1}) {
  return SetupHeroCard(completedGoals: completedGoals, completionProgress: completionProgress, setupXp: setupXp, level: level);
}

Widget SetupHeroCard({int completedGoals = 0, double completionProgress = 0.0, int setupXp = 0, int level = 1}) =>
    SetupHeroCardFactory(completedGoals: completedGoals, completionProgress: completionProgress, setupXp: setupXp, level: level);
