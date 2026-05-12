import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/social_cosmetic_avatar.dart';
import 'package:mathlearning/screens/user_profile_screen.dart';

void main() {
  testWidgets('shows user profile with honest empty cosmetic state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: UserProfileScreen(userId: '3')),
    );

    expect(find.text('User 3'), findsOneWidget);
    expect(find.text('Recent unlocks'), findsOneWidget);
    // No mock data — strip should show empty state text instead of fake items.
    expect(find.text('No cosmetic unlocks yet.'), findsOneWidget);
    expect(find.byType(RecentUnlocksStrip), findsOneWidget);
  });
}
