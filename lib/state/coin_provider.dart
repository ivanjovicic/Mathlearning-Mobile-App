import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/hint_models.dart';

class CoinProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  static const Duration _reloadDebounce = Duration(seconds: 4);

  int _coins = 0;
  UserDailyHints? _dailyHints;
  bool _isLoading = false;
  Future<void>? _loadInFlight;
  DateTime? _lastLoadedAt;

  int get coins => _coins;
  UserDailyHints? get dailyHints => _dailyHints;
  bool get isLoading => _isLoading;

  Future<void> loadCoinsAndHints({bool forceRefresh = false}) {
    if (!forceRefresh && _loadInFlight != null) {
      return _loadInFlight!;
    }

    final now = DateTime.now();
    final hasFreshData =
        _dailyHints != null &&
        _lastLoadedAt != null &&
        now.difference(_lastLoadedAt!) < _reloadDebounce;
    if (!forceRefresh && hasFreshData) {
      return Future.value();
    }

    final task = _loadCoinsAndHintsInternal().whenComplete(() {
      _loadInFlight = null;
    });
    _loadInFlight = task;
    return task;
  }

  Future<void> _loadCoinsAndHintsInternal() async {
    _isLoading = true;
    notifyListeners();

    try {
      final responses = await Future.wait<dynamic>([
        _api.getUserCoins(),
        _api.getDailyHintUsage(),
      ]);
      final coinsData = responses[0] as int?;
      final hintsData = responses[1] as Map<String, dynamic>?;

      _coins = coinsData ?? 10;

      _dailyHints = hintsData != null
          ? UserDailyHints.fromJson(hintsData)
          : UserDailyHints(userId: 'local', date: DateTime.now());
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      debugPrint('Error loading coins and hints: $e');
      // Fallback values
      _coins = 10; // Demo coins
      _dailyHints = UserDailyHints(userId: 'demo', date: DateTime.now());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool canAffordHint(String hintType) {
    final cost = HintCosts.getCost(hintType);

    // Check if user has free hints available
    if (_dailyHints?.canUseFreeHint(hintType) == true) {
      return true;
    }

    // Check if user has enough coins
    return _coins >= cost;
  }

  String getHintCostText(String hintType) {
    final cost = HintCosts.getCost(hintType);

    if (_dailyHints?.canUseFreeHint(hintType) == true) {
      return 'BESPLATNO';
    }

    return '$cost zlatnika';
  }

  // TODO(server-authoritative-rewards): this local mutation should be replaced by backend claim/refresh.
  void _spendCoins(int amount) {
    _coins = (_coins - amount).clamp(0, double.infinity).toInt();
    notifyListeners();
  }

  bool canAfford(int amount) => _coins >= amount;

  /// Generic coin spending for shop/power-ups (not only hints).
  bool trySpendCoins(int amount) {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _spendCoins(amount);
    return true;
  }

  void _useFreeHint(String hintType) {
    if (_dailyHints == null) return;
    final nextRemaining = _dailyHints!.remainingToday != null
        ? (_dailyHints!.remainingToday! - 1).clamp(0, 1000000)
        : null;

    switch (hintType) {
      case HintType.formula:
        _dailyHints = UserDailyHints(
          userId: _dailyHints!.userId,
          date: _dailyHints!.date,
          formulaHintsUsed: _dailyHints!.formulaHintsUsed + 1,
          clueHintsUsed: _dailyHints!.clueHintsUsed,
          eliminateHintsUsed: _dailyHints!.eliminateHintsUsed,
          remainingToday: nextRemaining,
          dailyLimit: _dailyHints!.dailyLimit,
          usedToday: (_dailyHints!.usedToday ?? 0) + 1,
        );
        break;
      case HintType.clue:
        _dailyHints = UserDailyHints(
          userId: _dailyHints!.userId,
          date: _dailyHints!.date,
          formulaHintsUsed: _dailyHints!.formulaHintsUsed,
          clueHintsUsed: _dailyHints!.clueHintsUsed + 1,
          eliminateHintsUsed: _dailyHints!.eliminateHintsUsed,
          remainingToday: nextRemaining,
          dailyLimit: _dailyHints!.dailyLimit,
          usedToday: (_dailyHints!.usedToday ?? 0) + 1,
        );
        break;
      case HintType.eliminate:
        _dailyHints = UserDailyHints(
          userId: _dailyHints!.userId,
          date: _dailyHints!.date,
          formulaHintsUsed: _dailyHints!.formulaHintsUsed,
          clueHintsUsed: _dailyHints!.clueHintsUsed,
          eliminateHintsUsed: _dailyHints!.eliminateHintsUsed + 1,
          remainingToday: nextRemaining,
          dailyLimit: _dailyHints!.dailyLimit,
          usedToday: (_dailyHints!.usedToday ?? 0) + 1,
        );
        break;
    }

    notifyListeners();
  }

  Future<bool> useHint(String hintType) async {
    if (!canAffordHint(hintType)) {
      return false;
    }

    // Use free hint if available
    if (_dailyHints?.canUseFreeHint(hintType) == true) {
      _useFreeHint(hintType);
      return true;
    }

    // Otherwise, spend coins
    final cost = HintCosts.getCost(hintType);
    _spendCoins(cost);
    return true;
  }

  // LOCAL_AUTHORITY_TODO: this coin mutation should be backend-confirmed on claim/refresh.
  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }
}
