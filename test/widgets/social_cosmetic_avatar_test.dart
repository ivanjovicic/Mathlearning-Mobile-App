import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/widgets/social_cosmetic_avatar.dart';

void main() {
  testWidgets('falls back gracefully when no cosmetics are equipped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocialCosmeticAvatar(
            userId: 'empty',
            displayName: 'Plain Player',
            loadout: SocialCosmeticLoadout(),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Plain Player default avatar'),
      findsOneWidget,
    );
    expect(find.text('RARE'), findsNothing);
  });

  testWidgets('recent unlock strip shows empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecentUnlocksStrip(unlocks: <SocialCosmeticUnlock>[]),
        ),
      ),
    );

    expect(find.text('No cosmetic unlocks yet.'), findsOneWidget);
  });

  testWidgets('NEW LOOK badge appears for current user after equip', (
    tester,
  ) async {
    final recentTs = DateTime.now()
        .subtract(const Duration(hours: 1))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'new_look_badge_set_at': recentTs,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocialCosmeticAvatar(
            userId: 'me',
            displayName: 'Current User',
            loadout: SocialCosmeticLoadout(),
            isCurrentUser: true,
          ),
        ),
      ),
    );

    // Wait for FutureBuilder to resolve.
    await tester.pumpAndSettle();

    expect(find.textContaining('NEW'), findsOneWidget);
  });

  testWidgets('NEW LOOK badge does not appear after 24 hours', (
    tester,
  ) async {
    final oldTs = DateTime.now()
        .subtract(const Duration(hours: 25))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'new_look_badge_set_at': oldTs,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocialCosmeticAvatar(
            userId: 'me',
            displayName: 'Current User',
            loadout: SocialCosmeticLoadout(),
            isCurrentUser: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('NEW'), findsNothing);
  });

  testWidgets('NEW LOOK badge does not appear for other users even if local badge is set', (
    tester,
  ) async {
    final recentTs = DateTime.now()
        .subtract(const Duration(hours: 1))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'new_look_badge_set_at': recentTs,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocialCosmeticAvatar(
            userId: 'other_user',
            displayName: 'Other Player',
            loadout: SocialCosmeticLoadout(),
            isCurrentUser: false, // not the local user
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('NEW'), findsNothing);
  });
}
