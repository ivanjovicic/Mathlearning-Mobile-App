import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakFreezeProvider extends ChangeNotifier {
  static const int maxCount = 2;
  static const int costCoins = 25;

  static const String _keyCount = 'streak_freeze_count_v1';

  bool _loaded = false;
  int _count = 0;

  bool get isLoaded => _loaded;
  int get count => _count;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_keyCount) ?? 0;
    _count = raw.clamp(0, maxCount);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCount, _count);
  }

  bool get isFull => _count >= maxCount;
  bool get hasAny => _count > 0;

  Future<bool> add(int amount) async {
    if (amount <= 0) return false;
    final next = (_count + amount).clamp(0, maxCount);
    if (next == _count) return false;
    _count = next;
    await _persist();
    notifyListeners();
    return true;
  }

  /// Consume up to [amount]. Returns how many were consumed.
  Future<int> consumeUpTo(int amount) async {
    if (amount <= 0 || _count <= 0) return 0;
    final used = amount.clamp(0, _count);
    _count -= used;
    await _persist();
    notifyListeners();
    return used;
  }
}

