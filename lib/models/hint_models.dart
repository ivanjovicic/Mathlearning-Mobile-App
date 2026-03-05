class HintType {
  static const String formula = 'formula';
  static const String clue = 'clue';
  static const String eliminate = 'eliminate';
}

class HintCosts {
  static const int formula = 5;
  static const int clue = 10;
  static const int eliminate = 15;

  static int getCost(String hintType) {
    switch (hintType) {
      case HintType.formula:
        return formula;
      case HintType.clue:
        return clue;
      case HintType.eliminate:
        return eliminate;
      default:
        return 0;
    }
  }
}

class DailyHintLimits {
  static const int freeFormulaHints = 1;
  static const int freeClueHints = 3;
  static const int freeEliminateHints = 1;

  static int getFreeLimit(String hintType) {
    switch (hintType) {
      case HintType.formula:
        return freeFormulaHints;
      case HintType.clue:
        return freeClueHints;
      case HintType.eliminate:
        return freeEliminateHints;
      default:
        return 0;
    }
  }
}

class UserDailyHints {
  final String userId;
  final DateTime date;
  final int formulaHintsUsed;
  final int clueHintsUsed;
  final int eliminateHintsUsed;
  final int? remainingToday;
  final int? dailyLimit;
  final int? usedToday;

  UserDailyHints({
    required this.userId,
    required this.date,
    this.formulaHintsUsed = 0,
    this.clueHintsUsed = 0,
    this.eliminateHintsUsed = 0,
    this.remainingToday,
    this.dailyLimit,
    this.usedToday,
  });

  factory UserDailyHints.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['userId'] ?? json['user_id'];
    final rawDate = json['date'] ?? json['Date'];

    return UserDailyHints(
      userId: rawUserId?.toString() ?? 'unknown',
      date: _parseDate(rawDate),
      formulaHintsUsed: _asInt(
        json['formulaHintsUsed'] ?? json['formula_hints_used'],
      ),
      clueHintsUsed: _asInt(json['clueHintsUsed'] ?? json['clue_hints_used']),
      eliminateHintsUsed: _asInt(
        json['eliminateHintsUsed'] ?? json['eliminate_hints_used'],
      ),
      remainingToday: json.containsKey('remaining')
          ? _asInt(json['remaining'])
          : null,
      dailyLimit: json.containsKey('dailyLimit')
          ? _asInt(json['dailyLimit'])
          : null,
      usedToday: json.containsKey('usedToday')
          ? _asInt(json['usedToday'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'formulaHintsUsed': formulaHintsUsed,
      'clueHintsUsed': clueHintsUsed,
      'eliminateHintsUsed': eliminateHintsUsed,
      'remaining': remainingToday,
      'dailyLimit': dailyLimit,
      'usedToday': usedToday,
    };
  }

  int getUsedHints(String hintType) {
    switch (hintType) {
      case HintType.formula:
        return formulaHintsUsed;
      case HintType.clue:
        return clueHintsUsed;
      case HintType.eliminate:
        return eliminateHintsUsed;
      default:
        return 0;
    }
  }

  bool canUseFreeHint(String hintType) {
    if (remainingToday != null) {
      return remainingToday! > 0;
    }

    final used = getUsedHints(hintType);
    final limit = DailyHintLimits.getFreeLimit(hintType);
    return used < limit;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
