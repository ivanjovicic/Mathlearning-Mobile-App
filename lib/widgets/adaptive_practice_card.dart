import 'package:flutter/material.dart';
import '../services/adaptive_learning_service.dart';

class AdaptivePracticeCard extends StatelessWidget {
  final AdaptivePracticeData practiceData;

  const AdaptivePracticeCard({super.key, required this.practiceData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Practice',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Topic: ${practiceData.topic}'),
            Text('Difficulty: ${practiceData.difficulty}'),
            Text('Questions: ${practiceData.questionCount}'),
            Text('Confidence: ${practiceData.confidence}'),
          ],
        ),
      ),
    );
  }
}
