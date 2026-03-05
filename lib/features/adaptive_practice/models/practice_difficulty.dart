enum PracticeDifficulty { easy, medium, hard, unknown }

PracticeDifficulty parsePracticeDifficulty(String? value) {
  switch (value?.toLowerCase().trim()) {
    case 'easy':
      return PracticeDifficulty.easy;
    case 'medium':
      return PracticeDifficulty.medium;
    case 'hard':
      return PracticeDifficulty.hard;
    default:
      return PracticeDifficulty.unknown;
  }
}

extension PracticeDifficultyX on PracticeDifficulty {
  String get apiValue {
    switch (this) {
      case PracticeDifficulty.easy:
        return 'easy';
      case PracticeDifficulty.medium:
        return 'medium';
      case PracticeDifficulty.hard:
        return 'hard';
      case PracticeDifficulty.unknown:
        return 'medium';
    }
  }

  int get level {
    switch (this) {
      case PracticeDifficulty.easy:
        return 1;
      case PracticeDifficulty.medium:
        return 2;
      case PracticeDifficulty.hard:
        return 3;
      case PracticeDifficulty.unknown:
        return 2;
    }
  }
}
