class HintType {
  static const String formula = 'formula';
  static const String clue = 'clue';
  static const String eliminate = 'eliminate';
}

class HintCosts {
  static const int formula = 2;
  static const int clue = 1;
  static const int eliminate = 3;

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

  UserDailyHints({
    required this.userId,
    required this.date,
    this.formulaHintsUsed = 0,
    this.clueHintsUsed = 0,
    this.eliminateHintsUsed = 0,
  });

  factory UserDailyHints.fromJson(Map<String, dynamic> json) {
    return UserDailyHints(
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      formulaHintsUsed: json['formulaHintsUsed'] ?? 0,
      clueHintsUsed: json['clueHintsUsed'] ?? 0,
      eliminateHintsUsed: json['eliminateHintsUsed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'formulaHintsUsed': formulaHintsUsed,
      'clueHintsUsed': clueHintsUsed,
      'eliminateHintsUsed': eliminateHintsUsed,
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
    final used = getUsedHints(hintType);
    final limit = DailyHintLimits.getFreeLimit(hintType);
    return used < limit;
  }
}