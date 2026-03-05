import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/path_node.dart';

void main() {
  test('PathNode.fromJson maps adaptive payload fields', () {
    final node = PathNode.fromJson({
      'id': 'node-1',
      'type': 'review',
      'topicId': 8,
      'topicName': 'Fractions',
      'difficulty': 'hard',
      'mastery': 67.5,
      'state': 'in_progress',
      'confidence': 'high',
      'xpReward': 30,
      'estimatedMinutes': 7,
      'dueReviewCount': 4,
    });

    expect(node.id, 'node-1');
    expect(node.type, PathNodeType.review);
    expect(node.topicId, 8);
    expect(node.topicName, 'Fractions');
    expect(node.difficulty, DifficultyLevel.hard);
    expect(node.state, PathNodeState.inProgress);
    expect(node.confidence, ConfidenceLevel.high);
    expect(node.dueReviewCount, 4);
  });
}
