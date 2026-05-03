import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/daily_reward.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_reward_chest.dart';
import 'package:mathlearning/features/learning_map/widgets/path_progress_card.dart';
import 'package:mathlearning/features/learning_map/widgets/streak_card.dart';
import 'package:mathlearning/features/learning_map/widgets/xp_level_chip.dart';
import 'package:mathlearning/state/progress_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => ProgressProvider(),
    child: MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: Scaffold(body: child),
    ),
  );
}

DailyReward _xpReward() {
  return const DailyReward(
    type: DailyRewardType.xp,
    title: '+35 XP',
    subtitle: 'A quick XP boost for today\'s adventure.',
    xpAmount: 35,
  );
}

SkillNode _node(String id, {required double mastery}) {
  return SkillNode(
    id: id,
    title: id,
    topicId: 1,
    subtopicId: 1,
    mastery: mastery,
    isLocked: false,
    recommendedDifficulty: SkillDifficulty.easy,
  );
}

// ---------------------------------------------------------------------------
// StreakCard
// ---------------------------------------------------------------------------

void main() {
  group('DailyRewardChest', () {
    testWidgets('locked state: shows locked copy and no open CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DailyRewardChest(
            state: DailyRewardChestState.locked,
            reward: _xpReward(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("Finish 1 practice round to unlock today's chest!"),
        findsOneWidget,
      );
      expect(find.text('Open reward'), findsNothing);
    });

    testWidgets('ready state: shows ready copy and open CTA', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DailyRewardChest(
            state: DailyRewardChestState.ready,
            reward: _xpReward(),
            onOpen: () async {},
          ),
        ),
      );
      await tester.pump(Duration.zero);

      expect(find.text('Daily reward ready!'), findsOneWidget);
      expect(find.text('Open reward'), findsOneWidget);
      expect(find.text('+35 XP'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('opened state: shows tomorrow copy and reward summary', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DailyRewardChest(
            state: DailyRewardChestState.opened,
            reward: _xpReward(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Come back tomorrow for a new one!'), findsOneWidget);
      expect(find.text('+35 XP'), findsOneWidget);
    });

    testWidgets('ready state CTA invokes onOpen', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        _wrap(
          DailyRewardChest(
            state: DailyRewardChestState.ready,
            reward: _xpReward(),
            onOpen: () async {
              opened = true;
            },
          ),
        ),
      );
      await tester.pump(Duration.zero);

      await tester.tap(find.text('Open reward'));
      await tester.pump(Duration.zero);

      expect(opened, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });

  group('StreakCard', () {
    testWidgets('new user (streak=0): shows start message', (tester) async {
      await tester.pumpWidget(
        _wrap(StreakCard(streakDays: 0, practicedToday: false)),
      );
      await tester.pump();

      expect(find.text('Start your streak today!'), findsOneWidget);
    });

    testWidgets('normal streak: shows day count', (tester) async {
      await tester.pumpWidget(
        _wrap(StreakCard(streakDays: 5, practicedToday: true)),
      );
      await tester.pump();

      expect(find.textContaining('5-Day Streak'), findsOneWidget);
    });

    testWidgets('at-risk streak: shows warning text', (tester) async {
      await tester.pumpWidget(
        _wrap(StreakCard(streakDays: 3, practicedToday: false)),
      );
      // pump(Duration.zero) explicitly elapses the fake clock by 0 so
      // flutter_animate's Timer(Duration.zero) created in initState fires.
      // pump() with no argument skips fakeAsync.elapse() entirely, leaving
      // that timer pending and failing the post-test invariant check.
      await tester.pump(Duration.zero);

      expect(find.textContaining("Don't lose your streak"), findsOneWidget);

      // Dispose the widget tree so the repeating shimmer Ticker is cancelled.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('streak milestone 7: shows correct encouragement',
        (tester) async {
      await tester.pumpWidget(
        _wrap(StreakCard(streakDays: 7, practicedToday: true)),
      );
      await tester.pump();

      expect(find.textContaining('One full week in a row!'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // PathProgressCard
  // -------------------------------------------------------------------------

  group('PathProgressCard', () {
    testWidgets('empty node list: renders nothing (SizedBox.shrink)',
        (tester) async {
      await tester.pumpWidget(_wrap(PathProgressCard(nodes: const [])));
      await tester.pump();

      // Should not render any visible card content.
      expect(find.textContaining('Your Journey So Far'), findsNothing);
    });

    testWidgets('computes mastered count (mastery >= 0.8)', (tester) async {
      final nodes = [
        _node('a', mastery: 0.9), // mastered
        _node('b', mastery: 0.8), // mastered (boundary)
        _node('c', mastery: 0.5), // not mastered
        _node('d', mastery: 0.1), // not mastered
      ];

      await tester.pumpWidget(_wrap(PathProgressCard(nodes: nodes)));
      await tester.pumpAndSettle();

      expect(find.text('2 / 4 skills unlocked'), findsOneWidget);
    });

    testWidgets('shows "X% of the map explored!" text', (tester) async {
      final nodes = [
        _node('a', mastery: 1.0),
        _node('b', mastery: 1.0),
      ];

      await tester.pumpWidget(_wrap(PathProgressCard(nodes: nodes)));
      await tester.pumpAndSettle();

      expect(find.textContaining('100% of the map explored!'), findsOneWidget);
    });

    testWidgets('single unmastered node: 0 of 1 skills', (tester) async {
      await tester.pumpWidget(
        _wrap(PathProgressCard(nodes: [_node('x', mastery: 0.3)])),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 / 1 skills unlocked'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // XpLevelChip
  // -------------------------------------------------------------------------

  group('XpLevelChip', () {
    testWidgets('displays level number', (tester) async {
      await tester.pumpWidget(
        _wrap(XpLevelChip(level: 5, xp: 120, xpToNextLevel: 200)),
      );
      await tester.pump();

      expect(find.textContaining('Level 5'), findsOneWidget);
    });

    testWidgets('shows remaining XP to next level', (tester) async {
      await tester.pumpWidget(
        _wrap(XpLevelChip(level: 3, xp: 50, xpToNextLevel: 300)),
      );
      await tester.pump();

      expect(find.textContaining('250 XP'), findsOneWidget);
    });

    testWidgets('at zero remaining XP: shows 0 XP to level up',
        (tester) async {
      await tester.pumpWidget(
        _wrap(XpLevelChip(level: 10, xp: 500, xpToNextLevel: 500)),
      );
      await tester.pump();

      expect(find.text('0 XP to level up!'), findsOneWidget);
    });
  });
}
