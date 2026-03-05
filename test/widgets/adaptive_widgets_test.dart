import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/path_node.dart';
import 'package:mathlearning/services/adaptive_learning_service.dart';
import 'package:mathlearning/widgets/adaptive_practice_card.dart';
import 'package:mathlearning/widgets/path_node_card.dart';
import 'package:mathlearning/widgets/path_node_details_sheet.dart';

void main() {
  const node = PathNode(
    id: 'node-1',
    type: PathNodeType.lesson,
    topicId: 2,
    topicName: 'Algebra',
    difficulty: DifficultyLevel.medium,
    mastery: 55,
    state: PathNodeState.available,
    confidence: ConfidenceLevel.med,
    xpReward: 20,
    estimatedMinutes: 5,
  );

  testWidgets('PathNodeCard renders topic and next badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: PathNodeCard(
              node: node,
              isRecommended: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Algebra'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('PathNodeDetailsSheet renders rewards and cta', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PathNodeDetailsSheet(node: node),
        ),
      ),
    );

    expect(find.text('Algebra'), findsOneWidget);
    expect(find.textContaining('Mastery'), findsOneWidget);
    expect(find.textContaining('Start Practice'), findsOneWidget);
  });

  testWidgets('AdaptivePracticeCard shows mapped payload values', (tester) async {
    final data = AdaptivePracticeData(
      topicId: 7,
      topic: 'Fractions',
      difficulty: 'easy',
      questionCount: 6,
      confidence: 'high',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdaptivePracticeCard(practiceData: data)),
      ),
    );

    expect(find.textContaining('Fractions'), findsOneWidget);
    expect(find.textContaining('easy'), findsOneWidget);
    expect(find.textContaining('6'), findsOneWidget);
  });
}
