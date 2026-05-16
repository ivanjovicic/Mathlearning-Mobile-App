import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_scoped_storage.dart';

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

/// Transactional reward steps.
///
/// These are persisted so a crash/restart can safely resume claim progress
/// without duplicating already-applied local rewards.
enum DailyChestRewardStep {
  xp,
  coins,
  cosmeticFragments,
  targetChaseProgress,
  seasonRewards,
  dailyReturnRewards,
}

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
  static const _legacyStoragePrefix = 'daily_run.state.v1.';
  static const _requiredRewardSteps = <DailyChestRewardStep>{
    DailyChestRewardStep.xp,
    DailyChestRewardStep.coins,
    DailyChestRewardStep.cosmeticFragments,
    DailyChestRewardStep.targetChaseProgress,
    DailyChestRewardStep.seasonRewards,
    DailyChestRewardStep.dailyReturnRewards,
  };

  String? _userId;
  bool _isStarted = false;
  DailyRunStage _currentStage = DailyRunStage.warmUp;
  int _stageIndex = 0;
  int _correctStreak = 0;
  bool _isCompleted = false;

  // Transactional chest flags (persisted).
  bool _chestOpeningInProgress = false;
  bool _rewardsApplied = false;
  bool _chestPermanentlyOpened = false;
  String? _activeRewardTransactionId;
  DateTime? _activeRewardTransactionCreatedAt;
  DailyChestReward? _activeRewardTransactionReward;
  Set<DailyChestRewardStep> _appliedRewardSteps = {};

  bool get isStarted => _isStarted;
  DailyRunStage get currentStage => _currentStage;
  int get currentStageIndex => _stageIndex;
  int get correctStreak => _correctStreak;
  bool get isCompleted => _isCompleted;

  bool get chestUnlocked => _isCompleted;
  bool get chestReady => _isCompleted && !_chestPermanentlyOpened;
  bool get chestOpeningInProgress => _chestOpeningInProgress;
  bool get rewardsApplied => _rewardsApplied;
  bool get chestPermanentlyOpened => _chestPermanentlyOpened;
  String? get activeRewardTransactionId => _activeRewardTransactionId;
  DailyChestReward? get activeRewardTransactionReward =>
      _activeRewardTransactionReward;

  /// Backward-compatible alias for older callers/tests.
  bool get chestOpened => _chestPermanentlyOpened;

  DailyChestState get chestState {
    if (_chestPermanentlyOpened) {
      return DailyChestState.opened;
    }
    if (chestReady) {
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
    final scopedUserId = UserScopedStorage.normalizeUserId(userId);
    _userId = scopedUserId;
    final now = DateTime.now();
    final storage = await SharedPreferences.getInstance();
    final key = _storageKey(scopedUserId, now);
    final legacyKey = _legacyStorageKey(scopedUserId, now);
    final raw = storage.getString(key) ?? storage.getString(legacyKey);
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

        // Backward-compatible migration:
        // old key `chestOpened` means a permanently-opened chest.
        _chestPermanentlyOpened =
            map['chestPermanentlyOpened'] == true || map['chestOpened'] == true;
        _chestOpeningInProgress = map['chestOpeningInProgress'] == true;
        _rewardsApplied = map['rewardsApplied'] == true;
        _activeRewardTransactionId = map['activeRewardTransactionId']
            ?.toString();
        _activeRewardTransactionCreatedAt = DateTime.tryParse(
          map['activeRewardTransactionCreatedAt']?.toString() ?? '',
        );
        _activeRewardTransactionReward = _rewardFromStorage(
          map['activeRewardTransactionReward'],
        );
        _appliedRewardSteps = _rewardStepsFromStorage(
          map['appliedRewardSteps'],
        );

        _normalizeRecoveredTransactionState();
      }
    } catch (_) {
      _resetForNewDay(notify: false);
    }

    // Migrate legacy key to the new user-scoped hierarchy.
    if (storage.getString(key) == null &&
        storage.getString(legacyKey) != null) {
      await storage.setString(key, raw);
      await storage.remove(legacyKey);
    }

    notifyListeners();
  }

  Future<void> startRun() async {
    _isStarted = true;
    _isCompleted = false;
    _correctStreak = 0;
    _stageIndex = 0;
    _currentStage = DailyRunStage.warmUp;
    _resetChestTransactionState();
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

  /// Creates or resumes a chest reward transaction.
  ///
  /// Important: this does NOT permanently open the chest.
  Future<DailyChestReward?> openChest() async {
    if (!chestReady) {
      return null;
    }

    // Resume unfinished transaction (crash-safe path).
    if (_activeRewardTransactionId != null) {
      _chestOpeningInProgress = true;
      _activeRewardTransactionReward ??= _buildDailyReward();
      _rewardsApplied = _hasAllRequiredRewardSteps();
      await _persist();
      notifyListeners();
      return _activeRewardTransactionReward;
    }

    // Create fresh transaction.
    final reward = _buildDailyReward();
    _activeRewardTransactionId = _createRewardTransactionId();
    _activeRewardTransactionCreatedAt = DateTime.now();
    _activeRewardTransactionReward = reward;
    _chestOpeningInProgress = false;
    _rewardsApplied = false;
    _appliedRewardSteps = {};
    await _persist();
    notifyListeners();
    return reward;
  }

  /// Used after external modifiers are resolved (featured/daily-return) so
  /// resume uses the exact same reward payload.
  Future<void> setTransactionReward({
    required DailyChestReward reward,
    String? expectedTransactionId,
  }) async {
    _assertActiveTransaction(expectedTransactionId: expectedTransactionId);
    _activeRewardTransactionReward = reward;
    await _persist();
    notifyListeners();
  }

  /// Called by the reward sheet right before animation-driven reward applying.
  Future<void> markRewardTransactionStarted({
    String? expectedTransactionId,
  }) async {
    _assertActiveTransaction(expectedTransactionId: expectedTransactionId);
    if (_chestOpeningInProgress) return;
    _chestOpeningInProgress = true;
    await _persist();
    notifyListeners();
  }

  bool isRewardStepApplied(DailyChestRewardStep step) {
    return _appliedRewardSteps.contains(step);
  }

  /// Applies one transactional reward step exactly once.
  ///
  /// If the same step is retried (restart/re-entry), this method becomes a no-op.
  Future<void> applyRewardStep({
    required DailyChestRewardStep step,
    required Future<void> Function() action,
    String? expectedTransactionId,
  }) async {
    _assertActiveTransaction(expectedTransactionId: expectedTransactionId);
    if (_chestPermanentlyOpened || _appliedRewardSteps.contains(step)) {
      return;
    }
    await action();
    _appliedRewardSteps = {..._appliedRewardSteps, step};
    _rewardsApplied = _hasAllRequiredRewardSteps();
    await _persist();
    notifyListeners();
  }

  /// Result-bearing variant of [applyRewardStep].
  Future<T?> applyRewardStepWithResult<T>({
    required DailyChestRewardStep step,
    required Future<T> Function() action,
    String? expectedTransactionId,
  }) async {
    _assertActiveTransaction(expectedTransactionId: expectedTransactionId);
    if (_chestPermanentlyOpened || _appliedRewardSteps.contains(step)) {
      return null;
    }
    final result = await action();
    _appliedRewardSteps = {..._appliedRewardSteps, step};
    _rewardsApplied = _hasAllRequiredRewardSteps();
    await _persist();
    notifyListeners();
    return result;
  }

  /// Finalization gate: chest is considered opened only after all transactional
  /// reward steps are confirmed as applied.
  Future<void> markChestPermanentlyOpened({
    String? expectedTransactionId,
  }) async {
    _assertActiveTransaction(expectedTransactionId: expectedTransactionId);
    if (_chestPermanentlyOpened) return;
    if (!_rewardsApplied) {
      throw StateError(
        'Cannot permanently open chest before all reward steps are applied.',
      );
    }

    _chestPermanentlyOpened = true;
    _chestOpeningInProgress = false;
    _activeRewardTransactionId = null;
    _activeRewardTransactionCreatedAt = null;
    _activeRewardTransactionReward = null;
    _appliedRewardSteps = {};
    await _persist();
    notifyListeners();
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
    _resetChestTransactionState();
    if (notify) {
      notifyListeners();
    }
  }

  void _resetChestTransactionState() {
    _chestOpeningInProgress = false;
    _rewardsApplied = false;
    _chestPermanentlyOpened = false;
    _activeRewardTransactionId = null;
    _activeRewardTransactionCreatedAt = null;
    _activeRewardTransactionReward = null;
    _appliedRewardSteps = {};
  }

  void _normalizeRecoveredTransactionState() {
    if (_chestPermanentlyOpened) {
      // Permanently opened should never keep a pending transaction.
      _chestOpeningInProgress = false;
      _rewardsApplied = true;
      _activeRewardTransactionId = null;
      _activeRewardTransactionCreatedAt = null;
      _activeRewardTransactionReward = null;
      _appliedRewardSteps = {};
      return;
    }

    final hasTransaction = _activeRewardTransactionId != null;
    if (!hasTransaction) {
      // Old payload or no transaction: keep chest ready/locked state only.
      _chestOpeningInProgress = false;
      _rewardsApplied = false;
      _activeRewardTransactionCreatedAt = null;
      _activeRewardTransactionReward = null;
      _appliedRewardSteps = {};
      return;
    }

    if (_activeRewardTransactionReward == null) {
      // If we crashed before the reward payload was persisted, reconstruct the
      // deterministic reward instead of dropping the transaction.
      _activeRewardTransactionReward = _buildDailyReward();
    }

    // Unfinished transactions stay resumable after restart.
    _chestOpeningInProgress = true;
    _rewardsApplied = _hasAllRequiredRewardSteps();
  }

  bool _hasAllRequiredRewardSteps() {
    for (final step in _requiredRewardSteps) {
      if (!_appliedRewardSteps.contains(step)) {
        return false;
      }
    }
    return true;
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

      // New transactional chest state.
      'chestOpeningInProgress': _chestOpeningInProgress,
      'rewardsApplied': _rewardsApplied,
      'chestPermanentlyOpened': _chestPermanentlyOpened,
      'activeRewardTransactionId': _activeRewardTransactionId,
      'activeRewardTransactionCreatedAt': _activeRewardTransactionCreatedAt
          ?.toIso8601String(),
      'activeRewardTransactionReward': _activeRewardTransactionReward == null
          ? null
          : _rewardToStorage(_activeRewardTransactionReward!),
      'appliedRewardSteps': _appliedRewardSteps.map((e) => e.name).toList(),

      // Backward-compatible key for older app versions.
      'chestOpened': _chestPermanentlyOpened,
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

  String _createRewardTransactionId() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final raw = '${_userId ?? 'local'}|$nowMs|$_stageIndex|$_correctStreak';
    var hash = 0;
    for (final code in raw.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return 'daily_chest_tx_${nowMs}_$hash';
  }

  Map<String, dynamic> _rewardToStorage(DailyChestReward reward) {
    return {
      'xp': reward.xp,
      'coins': reward.coins,
      'cosmeticFragment': reward.cosmeticFragment,
      'fragmentCopies': reward.fragmentCopies,
      'modifierLabels': reward.modifierLabels,
      'chestQualityLabel': reward.chestQualityLabel,
      'isComebackChest': reward.isComebackChest,
    };
  }

  DailyChestReward? _rewardFromStorage(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final xp = _asInt(map['xp']);
    final coins = _asInt(map['coins']);
    final fragment = map['cosmeticFragment']?.toString();
    if (xp == null || coins == null || fragment == null || fragment.isEmpty) {
      return null;
    }
    final labelsRaw = map['modifierLabels'];
    final labels = labelsRaw is List
        ? labelsRaw.whereType<Object>().map((e) => e.toString()).toList()
        : const <String>[];
    return DailyChestReward(
      xp: xp,
      coins: coins,
      cosmeticFragment: fragment,
      fragmentCopies: (_asInt(map['fragmentCopies']) ?? 1).clamp(1, 3),
      modifierLabels: labels,
      chestQualityLabel: map['chestQualityLabel']?.toString(),
      isComebackChest: map['isComebackChest'] == true,
    );
  }

  Set<DailyChestRewardStep> _rewardStepsFromStorage(dynamic raw) {
    if (raw is! List) return {};
    final steps = <DailyChestRewardStep>{};
    for (final value in raw) {
      final name = value?.toString();
      if (name == null || name.isEmpty) continue;
      for (final step in DailyChestRewardStep.values) {
        if (step.name == name) {
          steps.add(step);
          break;
        }
      }
    }
    return steps;
  }

  String _storageKey(String userId, DateTime when) {
    final day = _dateOnly(when);
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    final dayKey = '${day.year}-$month-$date';
    return UserScopedStorage.scopedKey(userId, 'daily_run', dayKey);
  }

  String _legacyStorageKey(String userId, DateTime when) {
    final day = _dateOnly(when);
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$_legacyStoragePrefix$userId.${day.year}-$month-$date';
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

  void _assertActiveTransaction({String? expectedTransactionId}) {
    final transactionId = _activeRewardTransactionId;
    if (transactionId == null) {
      throw StateError('No active daily chest reward transaction.');
    }
    if (expectedTransactionId != null &&
        transactionId != expectedTransactionId) {
      throw StateError(
        'Reward transaction mismatch. expected=$expectedTransactionId actual=$transactionId',
      );
    }
  }
}
