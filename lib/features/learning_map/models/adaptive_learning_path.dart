import 'dart:math' as math;

enum SkillDifficulty { easy, medium, hard }

SkillDifficulty parseSkillDifficulty(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'easy':
      return SkillDifficulty.easy;
    case 'hard':
      return SkillDifficulty.hard;
    default:
      return SkillDifficulty.medium;
  }
}

extension SkillDifficultyX on SkillDifficulty {
  String get label {
    switch (this) {
      case SkillDifficulty.easy:
        return 'easy';
      case SkillDifficulty.medium:
        return 'medium';
      case SkillDifficulty.hard:
        return 'hard';
    }
  }

  int get dots {
    switch (this) {
      case SkillDifficulty.easy:
        return 1;
      case SkillDifficulty.medium:
        return 2;
      case SkillDifficulty.hard:
        return 3;
    }
  }
}

class SkillNode {
  const SkillNode({
    required this.id,
    required this.title,
    required this.topicId,
    required this.subtopicId,
    required this.mastery,
    required this.isLocked,
    required this.recommendedDifficulty,
  });

  final String id;
  final String title;
  final int topicId;
  final int subtopicId;
  final double mastery;
  final bool isLocked;
  final SkillDifficulty recommendedDifficulty;

  double get mastery01 {
    if (mastery > 1) {
      return (mastery / 100).clamp(0.0, 1.0);
    }
    return mastery.clamp(0.0, 1.0);
  }

  SkillNode copyWith({double? mastery, bool? isLocked}) {
    return SkillNode(
      id: id,
      title: title,
      topicId: topicId,
      subtopicId: subtopicId,
      mastery: mastery ?? this.mastery,
      isLocked: isLocked ?? this.isLocked,
      recommendedDifficulty: recommendedDifficulty,
    );
  }

  factory SkillNode.fromJson(Map<String, dynamic> json) {
    return SkillNode(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['topicName'] ?? 'Skill').toString(),
      topicId: _asInt(json['topicId']) ?? 0,
      subtopicId: _asInt(json['subtopicId']) ?? 0,
      mastery: _asDouble(json['mastery']) ?? 0,
      isLocked: _asBool(json['isLocked']) ?? false,
      recommendedDifficulty: parseSkillDifficulty(
        json['recommendedDifficulty']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'topicId': topicId,
      'subtopicId': subtopicId,
      'mastery': mastery,
      'isLocked': isLocked,
      'recommendedDifficulty': recommendedDifficulty.label,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }
}

class SkillEdge {
  const SkillEdge({required this.from, required this.to});

  final String from;
  final String to;

  factory SkillEdge.fromJson(Map<String, dynamic> json) {
    return SkillEdge(
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'from': from, 'to': to};
}

class AdaptiveLearningPath {
  const AdaptiveLearningPath({
    required this.nodes,
    required this.edges,
    required this.recommendedNext,
    required this.generatedAt,
  });

  final List<SkillNode> nodes;
  final List<SkillEdge> edges;
  final String? recommendedNext;
  final DateTime generatedAt;

  SkillNode? get recommendedNextNode {
    final id = recommendedNext;
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  factory AdaptiveLearningPath.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'];
    final rawEdges = json['edges'];

    final nodes = rawNodes is List
        ? rawNodes
              .whereType<Map>()
              .map(
                (item) => SkillNode.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <SkillNode>[];

    final edges = rawEdges is List
        ? rawEdges
              .whereType<Map>()
              .map(
                (item) => SkillEdge.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <SkillEdge>[];

    return AdaptiveLearningPath(
      nodes: nodes,
      edges: edges,
      recommendedNext: json['recommendedNext']?.toString(),
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
      'edges': edges.map((edge) => edge.toJson()).toList(growable: false),
      'recommendedNext': recommendedNext,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
    };
  }

  AdaptiveLearningPath withUpdatedNode(String nodeId, double masteryDelta) {
    final updatedNodes = nodes
        .map(
          (node) => node.id == nodeId
              ? node.copyWith(
                  mastery: math.min(
                    1.0,
                    math.max(0.0, node.mastery01 + masteryDelta),
                  ),
                  isLocked: false,
                )
              : node,
        )
        .toList(growable: false);

    return AdaptiveLearningPath(
      nodes: updatedNodes,
      edges: edges,
      recommendedNext: recommendedNext,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  AdaptiveLearningPath copyWith({
    List<SkillNode>? nodes,
    List<SkillEdge>? edges,
    String? recommendedNext,
    DateTime? generatedAt,
  }) {
    return AdaptiveLearningPath(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      recommendedNext: recommendedNext ?? this.recommendedNext,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
