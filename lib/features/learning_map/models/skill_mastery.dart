class SkillMastery {
  const SkillMastery({
    required this.topicId,
    required this.topicName,
    required this.masteryProbability,
  });

  final int topicId;
  final String topicName;
  final double masteryProbability;

  double get mastery01 {
    if (masteryProbability > 1) {
      return (masteryProbability / 100).clamp(0.0, 1.0);
    }
    return masteryProbability.clamp(0.0, 1.0);
  }

  factory SkillMastery.fromJson(Map<String, dynamic> json) {
    return SkillMastery(
      topicId: _asInt(json['topicId']) ?? 0,
      topicName: (json['topicName'] ?? json['name'] ?? 'Topic').toString(),
      masteryProbability:
          _asDouble(json['masteryProbability'] ?? json['mastery']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'masteryProbability': masteryProbability,
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
}
