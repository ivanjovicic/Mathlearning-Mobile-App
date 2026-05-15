import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DailyRunStage { warmUp, challenge, finalGate }

extension DailyRunStageX on DailyRunStage {
  String get label {
    switch (this) {
      case DailyRunStage.warmUp:
        return 'Warm-up';
      case DailyRunStage.challenge:
        return 'Challenge';
      case DailyRunStage.finalGate:
        return 'Final Gate';
    }
  }
}

enum DailyChestState { locked, ready, opened }

class DailyChestReward {
  const DailyChestReward({
    required this.xp,
    required this.coins,
    required this.cosmeticFragment,
    this.fragmentCopies = 1,
    this.modifierLabels = const <String>[],
    this.chestQualityLabel,
    this.isComebackChest = false,
  });

  final int xp;
  final int coins;
  final String cosmeticFragment;
  final int fragmentCopies;
  final List<String> modifierLabels;
  final String? chestQualityLabel;
  final bool isComebackChest;

  DailyChestReward copyWith({
    int? xp,
    int? coins,
    String? cosmeticFragment,
    int? fragmentCopies,
    List<String>? modifierLabels,
    String? chestQualityLabel,
    bool? isComebackChest,
  }) {
    return DailyChestReward(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      cosmeticFragment: cosmeticFragment ?? this.cosmeticFragment,
      fragmentCopies: fragmentCopies ?? this.fragmentCopies,
      modifierLabels: modifierLabels ?? this.modifierLabels,
      chestQualityLabel: chestQualityLabel ?? this.chestQualityLabel,
      isComebackChest: isComebackChest ?? this.isComebackChest,
    );
  }
}

class DailyRunProvider extends ChangeNotifier {
  static const _storagePrefix = 'daily_run.state.v1.';

  String? _userId;
  bool _isStarted = false;
  DailyRunStage _currentStage = DailyRunStage.warmUp;
  int _stageIndex = 0;
  int _correctStreak = 0;
  bool _isCompleted = false;
  bool _chestOpened = false;

  bool get isStarted => _isStarted;
  DailyRunStage get currentStage => _currentStage;
  int get currentStageIndex => _stageIndex;
  int get correctStreak => _correctStreak;
  bool get isCompleted => _isCompleted;

  bool get chestUnlocked => _isCompleted;
  bool get chestOpened => _chestOpened;

  DailyChestState get chestState {
    if (_chestOpened) {
      return DailyChestState.opened;
    }
    if (_isCompleted) {
      return DailyChestState.ready;
    }
    return DailyChestState.locked;
  }

  double get displayedXpMultiplier {
    if (_correctStreak >= 5) {
      return 1.5;
    }
    if (_correctStreak >= 3) {
      return 1.2;
    }
    return 1.0;
  }

  Future<void> load(String userId) async {
    _userId = userId;
    final now = DateTime.now();
    final storage = await SharedPreferences.getInstance();
    final raw = storage.getString(_storageKey(userId, now));
    if (raw == null) {
      _resetForNewDay(notify: false);
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _resetForNewDay(notify: false);
      } else {
        final map = Map<String, dynamic>.from(decoded);
        _isStarted = map['isStarted'] == true;
        _currentStage = _parseStage(map['currentStage']?.toString());
        _stageIndex = _asInt(map['stageIndex'])?.clamp(0, 2) ?? 0;
        _correctStreak = _asInt(map['correctStreak'])?.clamp(0, 99) ?? 0;
        _isCompleted = map['isCompleted'] == true;
        _chestOpened = map['chestOpened'] == true;
      }
    } catch (_) {
      _resetForNewDay(notify: false);
    }

    notifyListeners();
  }

  Future<void> startRun() async {
    _isStarted = true;
    _isCompleted = false;
    _chestOpened = false;
    _correctStreak = 0;
    _stageIndex = 0;
    _currentStage = DailyRunStage.warmUp;
    await _persist();
    notifyListeners();
  }

  Future<void> moveToStage(int stageIndex) async {
    _stageIndex = stageIndex.clamp(0, 2);
    _currentStage = _stageFromIndex(_stageIndex);
    await _persist();
    notifyListeners();
  }

  Future<void> registerAnswerResult({required bool isCorrect}) async {
    if (isCorrect) {
      _correctStreak += 1;
    } else {
      _correctStreak = 0;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> markCompleted() async {
    _isStarted = false;
    _isCompleted = true;
    await _persist();
    notifyListeners();
  }

  Future<DailyChestReward?> openChest() async {
    if (chestState != DailyChestState.ready) {
      return null;
    }
    _chestOpened = true;
    await _persist();
    notifyListeners();
    return _buildDailyReward();
  }

  DailyChestReward previewReward() => _buildDailyReward();

  Future<void> clearRun() async {
    _resetForNewDay(notify: true);
    await _persist();
  }

  void _resetForNewDay({required bool notify}) {
    _isStarted = false;
    _currentStage = DailyRunStage.warmUp;
    _stageIndex = 0;
    _correctStreak = 0;
    _isCompleted = false;
    _chestOpened = false;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return;
    }
    final storage = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final payload = {
      'isStarted': _isStarted,
      'currentStage': _currentStage.name,
      'stageIndex': _stageIndex,
      'correctStreak': _correctStreak,
      'isCompleted': _isCompleted,
      'chestOpened': _chestOpened,
    };
    await storage.setString(_storageKey(userId, now), jsonEncode(payload));
  }

  DailyChestReward _buildDailyReward() {
    final userId = _userId ?? '';
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final seed = '$userId|$dateKey';
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    final xp = 25 + (hash % 26);
    final coins = 8 + (hash % 13);
    const fragments = <String>[
      'Nova Trail Fragment',
      'Comet Frame Fragment',
      'Neon Number Burst Fragment',
    ];
    final fragment = fragments[hash % fragments.length];
    return DailyChestReward(xp: xp, coins: coins, cosmeticFragment: fragment);
  }

  String _storageKey(String userId, DateTime when) {
    final day = _dateOnly(when);
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$_storagePrefix$userId.${day.year}-$month-$date';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DailyRunStage _parseStage(String? raw) {
    switch (raw) {
      case 'challenge':
        return DailyRunStage.challenge;
      case 'finalGate':
        return DailyRunStage.finalGate;
      case 'warmUp':
      default:
        return DailyRunStage.warmUp;
    }
  }

  DailyRunStage _stageFromIndex(int index) {
    switch (index) {
      case 1:
        return DailyRunStage.challenge;
      case 2:
        return DailyRunStage.finalGate;
      case 0:
      default:
        return DailyRunStage.warmUp;
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
