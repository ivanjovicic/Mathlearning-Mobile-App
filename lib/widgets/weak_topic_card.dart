import 'package:flutter/material.dart';
import '../services/adaptive_learning_service.dart';

class WeakTopicCard extends StatelessWidget {
  final WeakTopic weakTopic;

  const WeakTopicCard({super.key, required this.weakTopic});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(weakTopic.topic),
        subtitle: Text('Accuracy: ${weakTopic.accuracy.toStringAsFixed(1)}%'),
      ),
    );
  }
}
