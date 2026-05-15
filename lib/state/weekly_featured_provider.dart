import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cosmetic_item.dart';
import '../models/user_cosmetic.dart';
import '../models/weekly_featured_cosmetic.dart';
import '../services/weekly_featured_service.dart';
import 'daily_run_provider.dart';

class WeeklyFeaturedProvider extends ChangeNotifier {
  WeeklyFeaturedProvider({WeeklyFeaturedService? service})
    : _service = service ?? WeeklyFeaturedService.instance;

  final WeeklyFeaturedService _service;

  String? _userId;
  bool _isLoading = false;
  WeeklyFeaturedState? _state;

  bool get isLoading => _isLoading;
  WeeklyFeaturedState? get state => _state;
  WeeklyFeaturedCosmeticSet? get activeSet => _state?.activeSet;
  bool get completedActiveSet => _state?.isActiveSetCompleted ?? false;

  void configureUser(String? userId, {bool autoLoad = true}) {
    final safeUserId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    if (_userId == safeUserId) return;
    _userId = safeUserId;
    _isLoading = true;
    notifyListeners();
    if (autoLoad) {
      unawaited(load(userId: safeUserId));
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> load({String? userId, DateTime? now}) async {
    final safeUserId = userId == null || userId.trim().isEmpty
        ? _userId ?? 'local'
        : userId.trim();
    _userId = safeUserId;
    _isLoading = true;
    notifyListeners();
    _state = await _service.loadState(userId: safeUserId, now: now);
    _isLoading = false;
    notifyListeners();
  }

  DailyChestReward applyFeaturedBoost(
    DailyChestReward reward, {
    DateTime? now,
  }) {
    final set = activeSet;
    if (set == null) return reward;
    final fragment = _service.chooseDailyRunFragment(
      set: set,
      baseFragmentName: reward.cosmeticFragment,
      userId: _userId ?? 'local',
      now: now,
    );
    if (fragment == reward.cosmeticFragment) return reward;
    return reward.copyWith(cosmeticFragment: fragment);
  }

  Future<void> refreshCompletionFromInventory(
    List<UserCosmetic> inventory,
  ) async {
    final current = _state;
    if (current == null || current.isActiveSetCompleted) return;

    final ownedIds = inventory.map((entry) => entry.itemId).toSet();
    final completed = current.activeSet.itemIds.every(ownedIds.contains);
    if (!completed) return;

    final completedIds = <String>{
      ...current.completedRotationIds,
      current.activeSet.rotationId,
    }.toList(growable: false);
    final updated = current.copyWith(
      completedRotationIds: completedIds,
      updatedAt: DateTime.now(),
    );
    _state = updated;
    notifyListeners();
    await _service.saveState(updated, userId: _userId ?? 'local');
  }

  List<CosmeticItem> featuredItems(List<CosmeticItem> catalog) {
    return activeSet?.resolveItems(catalog) ?? const <CosmeticItem>[];
  }
}
