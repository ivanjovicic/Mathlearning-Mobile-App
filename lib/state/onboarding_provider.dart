import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const _completedKey = 'onboarding_completed';
  static const _difficultyKey = 'onboarding_difficulty';

  bool _isCompleted = false;
  bool _isLoaded = false;

  String _difficulty = 'Normal';
  bool _dailyReview = true;

  bool get isCompleted => _isCompleted;
  bool get isLoaded => _isLoaded;
  String get difficulty => _difficulty;
  bool get dailyReview => _dailyReview;

  OnboardingProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isCompleted = prefs.getBool(_completedKey) ?? false;
      _difficulty = prefs.getString(_difficultyKey) ?? 'Normal';
    } catch (e) {
      debugPrint('Onboarding load fallback: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  void setDifficulty(String value) {
    if (_difficulty == value) return;
    _difficulty = value;
    notifyListeners();
  }

  void setDailyReview(bool value) {
    if (_dailyReview == value) return;
    _dailyReview = value;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isCompleted = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, true);
      await prefs.setString(_difficultyKey, _difficulty);
    } catch (e) {
      debugPrint('Onboarding save fallback: $e');
    }
  }

  /// Reset onboarding (for testing or re-onboarding)
  Future<void> reset() async {
    _isCompleted = false;
    _difficulty = 'Normal';
    _dailyReview = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_completedKey);
      await prefs.remove(_difficultyKey);
    } catch (e) {
      debugPrint('Onboarding reset fallback: $e');
    }
  }
}
