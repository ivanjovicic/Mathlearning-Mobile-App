import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cosmetic_item.dart';
import '../models/player_identity.dart';
import '../models/user_cosmetic.dart';
import '../services/player_identity_service.dart';

/// Manages player identity: earned titles, selected title, and favorite
/// cosmetic.
///
/// Titles are computed from REAL data only — no fake achievements are created.
/// Call [refresh] when inventory, progress, or season data changes (typically
/// from a ProxyProvider update callback).
class PlayerIdentityProvider extends ChangeNotifier {
  PlayerIdentityProvider({PlayerIdentityService? service})
    : _service = service ?? PlayerIdentityService.instance;

  final PlayerIdentityService _service;

  String? _userId;
  bool _isLoading = false;

  // Persisted preferences
  String? _selectedTitleId;
  String? _favoriteCosmeticId;

  // Derived from external data via [refresh]
  List<PlayerTitle> _earnedTitles = const [];
  List<TrophyEntry> _trophies = const [];
  CosmeticRarity? _rarestRarity;
  String? _rarestItemId;
  String? _rarestItemName;
  int _currentStreak = 0;
  int _totalAttempts = 0;

  // ── Getters ────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  List<PlayerTitle> get earnedTitles => _earnedTitles;
  List<TrophyEntry> get trophies => _trophies;
  String? get selectedTitleId => _selectedTitleId;
  String? get favoriteCosmeticId => _favoriteCosmeticId;
  CosmeticRarity? get rarestOwnedRarity => _rarestRarity;
  String? get rarestOwnedItemId => _rarestItemId;
  String? get rarestOwnedItemName => _rarestItemName;
  int get currentStreak => _currentStreak;
  int get totalAttempts => _totalAttempts;
  bool get hasAnyTitle => _earnedTitles.isNotEmpty;

  /// The title selected by the user, falling back to the first earned title.
  PlayerTitle? get featuredTitle {
    final id = _selectedTitleId;
    if (id != null) {
      try {
        final t = PlayerTitle.values.firstWhere((t) => t.name == id);
        if (_earnedTitles.contains(t)) return t;
      } catch (_) {}
    }
    return _earnedTitles.isNotEmpty ? _earnedTitles.first : null;
  }

  @visibleForTesting
  PlayerIdentityService get debugService => _service;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void configureUser(String? userId, {bool autoLoad = true}) {
    final safeId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    if (_userId == safeId) return;
    _userId = safeId;
    _earnedTitles = const [];
    _trophies = const [];
    _rarestRarity = null;
    _rarestItemId = null;
    _rarestItemName = null;
    _selectedTitleId = null;
    _favoriteCosmeticId = null;
    _currentStreak = 0;
    _totalAttempts = 0;
    _isLoading = true;
    notifyListeners();
    if (autoLoad) {
      unawaited(_loadPreferences(safeId));
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recomputes earned titles and trophies from real data.
  /// Called from a ProxyProvider update callback when inventory, progress,
  /// or season data changes. Pure computation — no network calls.
  void refresh({
    required List<UserCosmetic> inventory,
    required List<CosmeticItem> catalog,
    required int currentStreak,
    required int totalAttempts,
    required int seasonCompletionPercent,
    String? completedSeasonName,
    String? completedSeasonId,
  }) {
    _currentStreak = currentStreak;
    _totalAttempts = totalAttempts;

    final newTitles = _service.computeEarnedTitles(
      inventory: inventory,
      catalog: catalog,
      currentStreak: currentStreak,
      totalAttempts: totalAttempts,
      seasonCompletionPercent: seasonCompletionPercent,
    );

    final rarest = _service.rarestOwned(inventory: inventory, catalog: catalog);
    _rarestRarity = rarest?.rarity;
    _rarestItemId = rarest?.itemId;
    _rarestItemName = rarest?.name;

    _trophies = _service.buildTrophies(
      inventory: inventory,
      catalog: catalog,
      totalAttempts: totalAttempts,
      completedSeasonName: completedSeasonName,
      completedSeasonId: completedSeasonId,
    );

    // If no titles changed (common case on minor updates), skip notification
    if (_listsEqual(_earnedTitles, newTitles) &&
        _rarestRarity == rarest?.rarity) {
      return;
    }

    _earnedTitles = newTitles;

    // Clear selected title if it's no longer earned
    if (_selectedTitleId != null) {
      final stillEarned = _earnedTitles.any((t) => t.name == _selectedTitleId);
      if (!stillEarned) _selectedTitleId = null;
    }

    notifyListeners();
  }

  Future<void> setSelectedTitle(PlayerTitle? title) async {
    if (!_earnedTitles.contains(title) && title != null) return;
    final userId = _userId ?? 'local';
    _selectedTitleId = title?.name;
    notifyListeners();
    await _service.saveSelectedTitle(userId, title?.name);
  }

  Future<void> setFavoriteCosmetic(String? itemId) async {
    final userId = _userId ?? 'local';
    _favoriteCosmeticId = itemId;
    notifyListeners();
    await _service.saveFavoriteCosmetic(userId, itemId);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _loadPreferences(String userId) async {
    try {
      _selectedTitleId = await _service.loadSelectedTitle(userId);
      _favoriteCosmeticId = await _service.loadFavoriteCosmetic(userId);
    } finally {
      if (_userId == userId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  bool _listsEqual(List<PlayerTitle> a, List<PlayerTitle> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @visibleForTesting
  Future<void> configureUserAndWait(String? userId) async {
    configureUser(userId);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
