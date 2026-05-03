import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/features/adaptive_practice/widgets/practice_celebration_page.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: child,
  );
}

PracticeCelebrationPage _page({
  int xpEarned = 64,
  int correctCount = 8,
  int totalQuestions = 10,
  double masteryDelta = 0.12,
  VoidCallback? onContinue,
}) {
  return PracticeCelebrationPage(
    xpEarned: xpEarned,
    correctCount: correctCount,
    totalQuestions: totalQuestions,
    masteryDelta: masteryDelta,
    onContinue: onContinue ?? () {},
  );
}

void main() {
  group('PracticeCelebrationPage', () {
    testWidgets('shows +XP earned stat', (tester) async {
      await tester.pumpWidget(_wrap(_page(xpEarned: 64)));
      await tester.pumpAndSettle();

      expect(find.textContaining('+64 XP earned!'), findsOneWidget);
    });

    testWidgets('shows questions nailed stat', (tester) async {
      await tester.pumpWidget(_wrap(_page(correctCount: 8, totalQuestions: 10)));
      await tester.pumpAndSettle();

      expect(find.textContaining('8/10 nailed it'), findsOneWidget);
    });

    testWidgets('shows skill power boost stat', (tester) async {
      await tester.pumpWidget(
        _wrap(_page(masteryDelta: 0.12)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Skill +12% stronger!'), findsOneWidget);
    });

    testWidgets('high accuracy (>=90%): shows fire praise', (tester) async {
      await tester.pumpWidget(
        _wrap(_page(correctCount: 9, totalQuestions: 10)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("You're on fire!"), findsOneWidget);
    });

    testWidgets('mid accuracy (70-89%): shows star praise', (tester) async {
      await tester.pumpWidget(
        _wrap(_page(correctCount: 7, totalQuestions: 10)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Great job!'), findsOneWidget);
    });

    testWidgets('low accuracy (<70%): shows encouragement praise',
        (tester) async {
      await tester.pumpWidget(
        _wrap(_page(correctCount: 5, totalQuestions: 10)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("Keep it up"), findsOneWidget);
    });

    testWidgets('CTA button invokes onContinue', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(_page(onContinue: () => tapped = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep going! →'));
      expect(tapped, isTrue);
    });

    testWidgets('zero mastery delta shows +0% stronger', (tester) async {
      await tester.pumpWidget(_wrap(_page(masteryDelta: 0.0)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Skill +0% stronger!'), findsOneWidget);
    });
  });
}
