class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    required this.goal,
    required this.rewardXp,
    required this.completed,
  });

  final String id;
  final String title;
  final String description;
  final String target;
  final int progress;
  final int goal;
  final int rewardXp;
  final bool completed;

  double get progress01 {
    if (goal <= 0) {
      return 0;
    }
    return (progress / goal).clamp(0.0, 1.0);
  }

  Quest copyWith({int? progress, bool? completed}) {
    return Quest(
      id: id,
      title: title,
      description: description,
      target: target,
      progress: progress ?? this.progress,
      goal: goal,
      rewardXp: rewardXp,
      completed: completed ?? this.completed,
    );
  }

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Quest').toString(),
      description: (json['description'] ?? '').toString(),
      target: (json['target'] ?? '').toString(),
      progress: _asInt(json['progress']) ?? 0,
      goal: _asInt(json['goal']) ?? 1,
      rewardXp: _asInt(json['rewardXp']) ?? 25,
      completed: json['completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target': target,
      'progress': progress,
      'goal': goal,
      'rewardXp': rewardXp,
      'completed': completed,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
