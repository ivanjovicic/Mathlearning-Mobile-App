import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/social_cosmetic_loadout.dart';
import '../widgets/social_cosmetic_avatar.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // No mock data — empty loadout is the honest default until the API
    // provides a real cosmeticLoadout for this user.
    const emptyLoadout = SocialCosmeticLoadout();

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SocialCosmeticAvatar(
                  userId: userId,
                  displayName: 'User $userId',
                  loadout: emptyLoadout,
                  size: 82,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User $userId',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No cosmetics available yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Recent unlocks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const RecentUnlocksStrip(unlocks: <SocialCosmeticUnlock>[]),
            const SizedBox(height: 20),
            Text(
              'XP Progress Chart',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 50),
                        const FlSpot(1, 100),
                        const FlSpot(2, 150),
                        const FlSpot(3, 200),
                        const FlSpot(4, 250),
                      ],
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Rank History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 10),
                        const FlSpot(1, 8),
                        const FlSpot(2, 6),
                        const FlSpot(3, 4),
                        const FlSpot(4, 2),
                      ],
                      isCurved: true,
                      color: Theme.of(context).colorScheme.secondary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
