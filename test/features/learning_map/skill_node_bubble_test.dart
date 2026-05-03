import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/skill_node_state.dart';
import 'package:mathlearning/features/learning_map/widgets/skill_node_bubble.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

SkillNode _node({
  String id = 'fractions',
  String title = 'Fractions Basics',
  double mastery = 0.2,
  bool isLocked = false,
}) {
  return SkillNode(
    id: id,
    title: title,
    topicId: 1,
    subtopicId: 1,
    mastery: mastery,
    isLocked: isLocked,
    recommendedDifficulty: SkillDifficulty.easy,
  );
}

void main() {
  group('SkillNodeBubble', () {
    testWidgets('available node shows level label and play state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SkillNodeBubble(
            node: _node(mastery: 0.2),
            state: SkillNodeState.recommended,
            progress: 0.2,
            semanticLabel: 'Fractions Basics, level 1, ready to play now',
            onTap: () {},
            showNextLabel: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('locked node shows locked state instead of progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SkillNodeBubble(
            node: _node(mastery: 0.6, isLocked: true),
            state: SkillNodeState.locked,
            progress: 0.6,
            semanticLabel: 'Fractions Basics, locked',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsWidgets);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('completed node shows done state with checkmark', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SkillNodeBubble(
            node: _node(mastery: 1.0),
            state: SkillNodeState.mastered,
            progress: 1.0,
            semanticLabel: 'Fractions Basics, done, level complete',
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DONE'), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('recently completed node shows floating XP and level label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SkillNodeBubble(
            node: _node(mastery: 0.6),
            state: SkillNodeState.learning,
            progress: 0.6,
            semanticLabel: 'Fractions Basics, level 2, ready to play',
            onTap: () {},
            showCompletionFeedback: true,
            completionXp: 64,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('+64 XP'), findsOneWidget);
      expect(find.text('Level Complete!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  });
}