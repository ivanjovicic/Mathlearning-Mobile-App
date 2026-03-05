import 'package:flutter/material.dart';
import '../models/school_leaderboard_models.dart';

class MySchoolCard extends StatelessWidget {
  final SchoolAggregateItem? school;

  const MySchoolCard({super.key, this.school});

  @override
  Widget build(BuildContext context) {
    if (school == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${school!.rank}')),
        title: Text(school!.schoolName),
        subtitle: Text('Score: ${school!.score}'),
      ),
    );
  }
}
