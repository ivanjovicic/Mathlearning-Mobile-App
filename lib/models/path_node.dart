// Domain model for a single node on the Learning Path.
//
// UI depends on this model and not on backend schema directly.
// Providers map backend/fallback payloads into these objects.

enum PathNodeType {
  lesson,
  review,
  checkpoint,
  challenge,
}

enum PathNodeState {
  locked,
  available,
  inProgress,
  completed,
}

enum DifficultyLevel { easy, medium, hard }

enum ConfidenceLevel { low, med, high }

class PathNode {
  final String id;
  final PathNodeType type;
  final int topicId;
  final String topicName;
  final String? subtopicName;
  final DifficultyLevel difficulty;
  final double mastery;
  final PathNodeState state;
  final String? recommendationReason;
  final ConfidenceLevel confidence;
  final int xpReward;
  final int estimatedMinutes;
  final int dueReviewCount;

  const PathNode({
    required this.id,
    required this.type,
    required this.topicId,
    required this.topicName,
    this.subtopicName,
    required this.difficulty,
    required this.mastery,
    required this.state,
    this.recommendationReason,
    required this.confidence,
    required this.xpReward,
    required this.estimatedMinutes,
    this.dueReviewCount = 0,
  });

  bool get isLocked => state == PathNodeState.locked;
  bool get isCompleted => state == PathNodeState.completed;
  bool get isAvailable => state == PathNodeState.available;

  factory PathNode.fromJson(Map<String, dynamic> json) {
    PathNodeType parseType(dynamic value) {
      switch (value?.toString().toLowerCase()) {
        case 'review':
          return PathNodeType.review;
        case 'checkpoint':
          return PathNodeType.checkpoint;
        case 'challenge':
          return PathNodeType.challenge;
        default:
          return PathNodeType.lesson;
      }
    }

    PathNodeState parseState(dynamic value) {
      switch (value?.toString().toLowerCase()) {
        case 'locked':
          return PathNodeState.locked;
        case 'in_progress':
        case 'inprogress':
          return PathNodeState.inProgress;
        case 'completed':
          return PathNodeState.completed;
        default:
          return PathNodeState.available;
      }
    }

    DifficultyLevel parseDifficulty(dynamic value) {
      switch (value?.toString().toLowerCase()) {
        case 'easy':
          return DifficultyLevel.easy;
        case 'hard':
          return DifficultyLevel.hard;
        default:
          return DifficultyLevel.medium;
      }
    }

    ConfidenceLevel parseConfidence(dynamic value) {
      switch (value?.toString().toLowerCase()) {
        case 'low':
          return ConfidenceLevel.low;
        case 'high':
          return ConfidenceLevel.high;
        default:
          return ConfidenceLevel.med;
      }
    }

    int asInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double asDouble(dynamic value, [double fallback = 0]) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    return PathNode(
      id: (json['id'] ?? '').toString(),
      type: parseType(json['type']),
      topicId: asInt(json['topicId'] ?? json['topic_id'], 1),
      topicName: (json['topicName'] ?? json['topic'] ?? 'Practice').toString(),
      subtopicName: json['subtopicName']?.toString(),
      difficulty: parseDifficulty(json['difficulty']),
      mastery: asDouble(json['mastery'] ?? json['masteryScore']),
      state: parseState(json['state']),
      recommendationReason: json['recommendationReason']?.toString(),
      confidence: parseConfidence(json['confidence']),
      xpReward: asInt(json['xpReward'] ?? json['xp'], 20),
      estimatedMinutes: asInt(
        json['estimatedTime'] ?? json['estimatedMinutes'],
        5,
      ),
      dueReviewCount: asInt(json['dueReviewCount'] ?? json['dueCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'topicId': topicId,
      'topicName': topicName,
      'subtopicName': subtopicName,
      'difficulty': difficulty.name,
      'mastery': mastery,
      'state': state.name,
      'recommendationReason': recommendationReason,
      'confidence': confidence.name,
      'xpReward': xpReward,
      'estimatedMinutes': estimatedMinutes,
      'dueReviewCount': dueReviewCount,
    };
  }

  PathNode copyWith({
    PathNodeState? state,
    double? mastery,
    int? dueReviewCount,
  }) {
    return PathNode(
      id: id,
      type: type,
      topicId: topicId,
      topicName: topicName,
      subtopicName: subtopicName,
      difficulty: difficulty,
      mastery: mastery ?? this.mastery,
      state: state ?? this.state,
      recommendationReason: recommendationReason,
      confidence: confidence,
      xpReward: xpReward,
      estimatedMinutes: estimatedMinutes,
      dueReviewCount: dueReviewCount ?? this.dueReviewCount,
    );
  }
}
