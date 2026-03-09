import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/services/adaptive_learning_service.dart';
import 'package:mathlearning/widgets/weak_topic_card.dart';

void main() {
  testWidgets('WeakTopicCard renders topic and accuracy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeakTopicCard(
            weakTopic: WeakTopic(topic: 'Fractions', accuracy: 42.5),
          ),
        ),
      ),
    );

    expect(find.text('Fractions'), findsOneWidget);
    expect(find.text('42.5%'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
  });
}
