class PendingProgressEventType {
  static const String answer = 'answer';
  static const String practiceReward = 'practice_reward';
  static const String bonusXp = 'bonus_xp';
  static const String streakRoll = 'streak_roll';
}

class PendingProgressEvent {
  const PendingProgressEvent({
    required this.id,
    required this.type,
    required this.timestampMs,
    this.xp,
    this.isCorrect,
    this.freezesUsed,
    this.streakBroken,
    this.dayKey,
  });

  final String id;
  final String type;
  final int timestampMs;
  final int? xp;
  final bool? isCorrect;
  final int? freezesUsed;
  final bool? streakBroken;
  final String? dayKey;

  factory PendingProgressEvent.fromJson(Map<String, dynamic> json) {
    return PendingProgressEvent(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      timestampMs: (json['timestamp'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt(),
      isCorrect: json['isCorrect'] == null ? null : json['isCorrect'] == true,
      freezesUsed: (json['freezesUsed'] as num?)?.toInt(),
      streakBroken: json['streakBroken'] == null
          ? null
          : json['streakBroken'] == true,
      dayKey: json['dayKey']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestampMs,
      if (xp != null) 'xp': xp,
      if (isCorrect != null) 'isCorrect': isCorrect,
      if (freezesUsed != null) 'freezesUsed': freezesUsed,
      if (streakBroken != null) 'streakBroken': streakBroken,
      if (dayKey != null) 'dayKey': dayKey,
    };
  }
}

class PendingLocalProgress {
  const PendingLocalProgress({required this.events});

  final List<PendingProgressEvent> events;

  static const PendingLocalProgress empty = PendingLocalProgress(events: []);

  bool get hasPending => events.isNotEmpty;

  int get pendingAnswerCount =>
      events.where((e) => e.type == PendingProgressEventType.answer).length;

  int get pendingCorrectAnswers => events
      .where(
        (e) => e.type == PendingProgressEventType.answer && e.isCorrect == true,
      )
      .length;

  int get xpDelta => events
      .where(
        (e) =>
            e.type == PendingProgressEventType.answer ||
            e.type == PendingProgressEventType.practiceReward ||
            e.type == PendingProgressEventType.bonusXp,
      )
      .fold(0, (sum, e) => sum + (e.xp ?? 0));

  ({int freezesUsed, bool streakBroken})? get latestStreakRoll {
    for (final event in events.reversed) {
      if (event.type == PendingProgressEventType.streakRoll) {
        return (
          freezesUsed: event.freezesUsed ?? 0,
          streakBroken: event.streakBroken ?? false,
        );
      }
    }
    return null;
  }

  bool hasPracticeRewardOnDay(String dayKey) {
    return events.any(
      (e) =>
          e.type == PendingProgressEventType.practiceReward &&
          e.dayKey == dayKey,
    );
  }

  PendingLocalProgress add(PendingProgressEvent event) {
    return PendingLocalProgress(
      events: List<PendingProgressEvent>.unmodifiable([...events, event]),
    );
  }

  PendingLocalProgress clear() => empty;

  List<Map<String, dynamic>> toJsonList() {
    return events.map((e) => e.toJson()).toList(growable: false);
  }

  static PendingLocalProgress fromJsonList(List<Map<String, dynamic>> list) {
    return PendingLocalProgress(
      events: list
          .map(PendingProgressEvent.fromJson)
          .where((event) => event.id.isNotEmpty && event.type.isNotEmpty)
          .toList(growable: false),
    );
  }
}
