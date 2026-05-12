import 'package:flutter/foundation.dart';

import '../models/cosmetic_item.dart';
import '../models/cosmetic_fragment_progress.dart';
import '../models/user_avatar.dart';
import '../models/user_cosmetic.dart';
import '../services/cosmetics_service.dart';
import '../services/auth_service.dart';

class AvatarProvider extends ChangeNotifier {
  final CosmeticsService _service = CosmeticsService.instance;

  bool _isLoading = false;
  String? _error;

  UserAvatar? _avatarConfig;
  List<UserCosmetic> _inventory = [];
  List<CosmeticItem> _catalog = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserAvatar? get avatarConfig => _avatarConfig;
  List<UserCosmetic> get inventory => List.unmodifiable(_inventory);
  List<CosmeticItem> get catalog => List.unmodifiable(_catalog);

  /// Whether the user owns a specific cosmetic item.
  bool owns(String itemId) => _inventory.any((c) => c.itemId == itemId);

  /// Returns items owned by the user for a given category.
  List<CosmeticItem> ownedItemsForCategory(CosmeticCategory category) {
    final ownedIds = _inventory.map((c) => c.itemId).toSet();
    return _catalog
        .where(
          (item) => item.category == category && ownedIds.contains(item.id),
        )
        .toList();
  }

  /// Returns all items in the catalog for a given category,
  /// with a flag indicating whether each is owned.
  List<({CosmeticItem item, bool owned})> catalogForCategory(
    CosmeticCategory category,
  ) {
    final ownedIds = _inventory.map((c) => c.itemId).toSet();
    return _catalog
        .where((item) => item.category == category)
        .map((item) => (item: item, owned: ownedIds.contains(item.id)))
        .toList()
      ..sort((a, b) {
        // Owned first, then by rarity desc
        if (a.owned != b.owned) return a.owned ? -1 : 1;
        return b.item.rarity.index.compareTo(a.item.rarity.index);
      });
  }

  /// The item ID currently equipped in a given category slot.
  String? equippedIdFor(CosmeticCategory category) {
    return _avatarConfig?.slotFor(category.id);
  }

  /// The equipped CosmeticItem for a given category, if any.
  CosmeticItem? equippedItemFor(CosmeticCategory category) {
    final id = equippedIdFor(category);
    if (id == null) return null;
    try {
      return _catalog.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────── LOAD ───────────────────────────────────

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _catalog = _service.getCatalog();
      final results = await Future.wait([
        _service.loadInventory(),
        _service.loadAvatarConfig(),
      ]);
      _inventory = results[0] as List<UserCosmetic>;
      _avatarConfig = results[1] as UserAvatar;
    } catch (e) {
      _error = e.toString();
      debugPrint('[AvatarProvider] load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _avatarConfig = null;
    _inventory = [];
    _error = null;
    notifyListeners();
  }

  /// Saves the avatar config directly (used by customization screen preview flow).
  Future<void> updateAvatarConfig(UserAvatar config) async {
    _avatarConfig = config;
    notifyListeners();
    await _service.updateAvatarConfig(config);
  }

  // ─────────────────────── EQUIP ──────────────────────────────────

  /// Equips an item in its category slot.
  Future<void> equipItem(CosmeticItem item) async {
    if (!owns(item.id)) return;

    final userId = AuthService.instance.userId ?? 'local';
    final current = _avatarConfig ?? UserAvatar.defaults(userId);

    final updated = _applyEquip(current, item);
    _avatarConfig = updated;
    notifyListeners();

    await _service.updateAvatarConfig(updated);
  }

  /// Unequips a slot by category.
  Future<void> unequipSlot(CosmeticCategory category) async {
    if (_avatarConfig == null) return;
    final updated = _clearSlot(_avatarConfig!, category);
    _avatarConfig = updated;
    notifyListeners();
    await _service.updateAvatarConfig(updated);
  }

  UserAvatar _applyEquip(UserAvatar config, CosmeticItem item) {
    switch (item.category) {
      case CosmeticCategory.avatarSkin:
        return config.copyWith(skinId: item.id);
      case CosmeticCategory.hairStyle:
        return config.copyWith(hairId: item.id);
      case CosmeticCategory.clothing:
        return config.copyWith(clothingId: item.id);
      case CosmeticCategory.accessory:
        return config.copyWith(accessoryId: item.id);
      case CosmeticCategory.emojiReaction:
        return config.copyWith(emojiId: item.id);
      case CosmeticCategory.avatarFrame:
        return config.copyWith(frameId: item.id);
      case CosmeticCategory.profileBackground:
        return config.copyWith(backgroundId: item.id);
      case CosmeticCategory.animatedEffect:
        return config.copyWith(animatedEffectId: item.id);
      default:
        return config;
    }
  }

  UserAvatar _clearSlot(UserAvatar config, CosmeticCategory category) {
    switch (category) {
      case CosmeticCategory.avatarSkin:
        return config.copyWith(clearSkin: true);
      case CosmeticCategory.hairStyle:
        return config.copyWith(clearHair: true);
      case CosmeticCategory.clothing:
        return config.copyWith(clearClothing: true);
      case CosmeticCategory.accessory:
        return config.copyWith(clearAccessory: true);
      case CosmeticCategory.emojiReaction:
        return config.copyWith(clearEmoji: true);
      case CosmeticCategory.avatarFrame:
        return config.copyWith(clearFrame: true);
      case CosmeticCategory.profileBackground:
        return config.copyWith(clearBackground: true);
      case CosmeticCategory.animatedEffect:
        return config.copyWith(clearAnimatedEffect: true);
      default:
        return config;
    }
  }

  // ─────────────────────── UNLOCK ─────────────────────────────────

  /// Grants an item to the user's inventory (called by game events).
  Future<CosmeticItem?> grantItem({
    required String itemId,
    required String sourceType,
    String? sourceEvent,
  }) async {
    if (owns(itemId)) return null;
    final item = _catalog.where((c) => c.id == itemId).firstOrNull;
    if (item == null) return null;

    final unlocked = await _service.unlockItem(
      itemId: itemId,
      sourceType: sourceType,
      sourceEvent: sourceEvent,
    );
    if (unlocked != null) {
      _inventory = [..._inventory, unlocked];
      notifyListeners();
      return item;
    }
    return null;
  }

  Future<DailyRunCosmeticGrantResult> grantDailyRunFragment(
    String fragmentName,
  ) async {
    if (_catalog.isEmpty) {
      _catalog = _service.getCatalog();
    }
    final result = await _service.grantDailyRunFragment(
      fragmentName: fragmentName,
    );
    if (result.unlockedCosmetic != null && !owns(result.item.id)) {
      _inventory = [..._inventory, result.unlockedCosmetic!];
      notifyListeners();
    }
    return result;
  }

  // ─────────────────────── LEVEL-UP HOOK ──────────────────────────

  /// Called when the user reaches a new level.
  /// Automatically grants cosmetics tied to that level.
  Future<List<CosmeticItem>> onLevelUp(int newLevel) async {
    final unlocks = <CosmeticItem>[];
    final levelUnlocks = _levelUnlockMap[newLevel] ?? [];
    for (final itemId in levelUnlocks) {
      final item = await grantItem(itemId: itemId, sourceType: 'level_up');
      if (item != null) unlocks.add(item);
    }
    return unlocks;
  }

  static const Map<int, List<String>> _levelUnlockMap = {
    3: ['hair_curly'],
    5: ['hair_long', 'frame_silver'],
    7: ['clothing_hoodie'],
    8: ['bg_chalkboard'],
    10: ['skin_golden'],
    12: ['frame_blue_glow'],
    15: ['hair_afro'],
    18: ['bg_galaxy'],
    20: ['clothing_scifi'],
    25: ['skin_galaxy'],
    30: ['acc_vr_goggles'],
    40: ['bg_circuit'],
  };

  // ─────────────────────── STREAK HOOK ────────────────────────────

  /// Called when the user reaches a streak milestone.
  Future<List<CosmeticItem>> onStreakMilestone(int streakDays) async {
    final unlocks = <CosmeticItem>[];
    final unlockMap = {
      7: 'emoji_fire',
      14: 'hair_mohawk',
      30: 'frame_streak_flame',
    };
    final itemId = unlockMap[streakDays];
    if (itemId != null) {
      final item = await grantItem(itemId: itemId, sourceType: 'streak');
      if (item != null) unlocks.add(item);
    }
    return unlocks;
  }
}
