import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/hint_models.dart';

class CoinProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  int _coins = 0;
  UserDailyHints? _dailyHints;
  bool _isLoading = false;

  int get coins => _coins;
  UserDailyHints? get dailyHints => _dailyHints;
  bool get isLoading => _isLoading;

  Future<void> loadCoinsAndHints() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load coins
      final coinsData = await _api.getUserCoins();
      _coins = coinsData ?? 10;

      // Load daily hints usage
      final hintsData = await _api.getDailyHintUsage();
      _dailyHints = hintsData != null
          ? UserDailyHints.fromJson(hintsData)
          : UserDailyHints(userId: 'local', date: DateTime.now());
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

  void _spendCoins(int amount) {
    _coins = (_coins - amount).clamp(0, double.infinity).toInt();
    notifyListeners();
  }

  void _useFreeHint(String hintType) {
    if (_dailyHints == null) return;

    switch (hintType) {
      case HintType.formula:
        _dailyHints = UserDailyHints(
          userId: _dailyHints!.userId,
          date: _dailyHints!.date,
          formulaHintsUsed: _dailyHints!.formulaHintsUsed + 1,
          clueHintsUsed: _dailyHints!.clueHintsUsed,
          eliminateHintsUsed: _dailyHints!.eliminateHintsUsed,
        );
        break;
      case HintType.clue:
        _dailyHints = UserDailyHints(
          userId: _dailyHints!.userId,
          date: _dailyHints!.date,
          formulaHintsUsed: _dailyHints!.formulaHintsUsed,
          clueHintsUsed: _dailyHints!.clueHintsUsed + 1,
          eliminateHintsUsed: _dailyHints!.eliminateHintsUsed,
        );
        break;
      case HintType.eliminate:
        _dailyHints = UserDailyHints(
          userId: _dailyHints!.userId,
          date: _dailyHints!.date,
          formulaHintsUsed: _dailyHints!.formulaHintsUsed,
          clueHintsUsed: _dailyHints!.clueHintsUsed,
          eliminateHintsUsed: _dailyHints!.eliminateHintsUsed + 1,
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

  // Add coins (for rewards, purchases, etc.)
  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }
}
