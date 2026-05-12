import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cosmetic_fragment_progress.dart';
import '../models/cosmetic_item.dart';
import '../models/user_avatar.dart';
import '../models/user_cosmetic.dart';
import 'auth_service.dart';

/// Manages the cosmetics catalog, user inventory, and equipped avatar config.
///
/// Strategy:
///  1. Static local catalog is always available (offline-first).
///  2. Avatar config is persisted in SharedPreferences and synced to backend.
///  3. Inventory is persisted locally and synced from backend when online.
class CosmeticsService {
  static final CosmeticsService instance = CosmeticsService._();
  CosmeticsService._();

  static const _avatarKey = 'user_avatar_config';
  static const _inventoryKey = 'user_cosmetics_inventory';
  static const _fragmentProgressKey = 'user_cosmetic_fragment_progress_v1';
  static const dailyRunRequiredFragments = 5;

  // ─────────────────────────── CATALOG ───────────────────────────

  /// Returns the full static cosmetic catalog.
  List<CosmeticItem> getCatalog() => _buildCatalog();

  List<CosmeticItem> getCatalogByCategory(CosmeticCategory category) =>
      getCatalog().where((c) => c.category == category).toList();

  // ──────────────────────── INVENTORY ────────────────────────────

  Future<List<UserCosmetic>> loadInventory() async {
    try {
      final client = AuthService.instance.client;
      final response = await client.get('/api/cosmetics/inventory');
      if (response.statusCode == 200) {
        final data = response.data;
        final remoteItems = (data['items'] as List<dynamic>? ?? [])
            .map((e) => UserCosmetic.fromJson(e as Map<String, dynamic>))
            .toList();
        final items = _mergeInventory(
          remoteItems,
          await _loadInventoryLocally(),
        );
        await _saveInventoryLocally(items);
        return items;
      }
    } catch (e) {
      debugPrint('[CosmeticsService] loadInventory from API failed: $e');
    }
    return _loadInventoryLocally();
  }

  Future<void> _saveInventoryLocally(List<UserCosmetic> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(items.map((i) => i.toJson()).toList());
      await prefs.setString(_inventoryKey, json);
    } catch (e) {
      debugPrint('[CosmeticsService] save inventory locally failed: $e');
    }
  }

  Future<List<UserCosmetic>> _loadInventoryLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_inventoryKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        return list
            .map((e) => UserCosmetic.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[CosmeticsService] load inventory locally failed: $e');
    }
    // First time: give the user starter items
    return _starterInventory();
  }

  List<UserCosmetic> _mergeInventory(
    List<UserCosmetic> primary,
    List<UserCosmetic> secondary,
  ) {
    final byItemId = <String, UserCosmetic>{};
    for (final item in secondary) {
      byItemId[item.itemId] = item;
    }
    for (final item in primary) {
      byItemId[item.itemId] = item;
    }
    return byItemId.values.toList();
  }

  /// Returns a set of starter cosmetic items for new users.
  List<UserCosmetic> _starterInventory() {
    final userId = AuthService.instance.userId ?? 'local';
    final now = DateTime.now();
    return [
      UserCosmetic(
        id: 'starter_skin_default',
        userId: userId,
        itemId: 'skin_default',
        unlockedAt: now,
        sourceType: 'starter',
      ),
      UserCosmetic(
        id: 'starter_hair_default',
        userId: userId,
        itemId: 'hair_default',
        unlockedAt: now,
        sourceType: 'starter',
      ),
      UserCosmetic(
        id: 'starter_clothing_default',
        userId: userId,
        itemId: 'clothing_default',
        unlockedAt: now,
        sourceType: 'starter',
      ),
      UserCosmetic(
        id: 'starter_emoji_default',
        userId: userId,
        itemId: 'emoji_default',
        unlockedAt: now,
        sourceType: 'starter',
      ),
      UserCosmetic(
        id: 'starter_bg_default',
        userId: userId,
        itemId: 'bg_default',
        unlockedAt: now,
        sourceType: 'starter',
      ),
    ];
  }

  // ────────────────────── AVATAR CONFIG ──────────────────────────

  Future<UserAvatar> loadAvatarConfig() async {
    final userId = AuthService.instance.userId ?? 'local';
    try {
      final client = AuthService.instance.client;
      final response = await client.get('/api/cosmetics/avatar');
      if (response.statusCode == 200) {
        final config = UserAvatar.fromJson(
          response.data as Map<String, dynamic>,
        );
        await _saveAvatarLocally(config);
        return config;
      }
    } catch (e) {
      debugPrint('[CosmeticsService] loadAvatarConfig from API failed: $e');
    }
    return _loadAvatarLocally(userId);
  }

  Future<bool> updateAvatarConfig(UserAvatar config) async {
    await _saveAvatarLocally(config);
    try {
      final client = AuthService.instance.client;
      final response = await client.put(
        '/api/cosmetics/avatar',
        data: config.toJson(),
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      debugPrint('[CosmeticsService] updateAvatarConfig API failed: $e');
      return false; // Saved locally — will sync later.
    }
  }

  Future<void> _saveAvatarLocally(UserAvatar config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarKey, jsonEncode(config.toJson()));
    } catch (e) {
      debugPrint('[CosmeticsService] save avatar locally failed: $e');
    }
  }

  Future<UserAvatar> _loadAvatarLocally(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_avatarKey);
      if (raw != null) {
        return UserAvatar.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[CosmeticsService] load avatar locally failed: $e');
    }
    return UserAvatar.defaults(userId);
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ DAILY RUN FRAGMENTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<DailyRunCosmeticGrantResult> grantDailyRunFragment({
    required String fragmentName,
    int fragmentAmount = 1,
  }) async {
    final item = dailyRunItemForFragment(fragmentName);
    final now = DateTime.now();
    final progressMap = await _loadFragmentProgressMap();
    final current =
        progressMap[item.id] ??
        CosmeticFragmentProgress(
          itemId: item.id,
          collectedFragments: 0,
          requiredFragments: dailyRunRequiredFragments,
          updatedAt: now,
        );
    final inventory = await _loadInventoryLocally();
    final alreadyOwned = inventory.any((entry) => entry.itemId == item.id);
    final previous = alreadyOwned
        ? current.requiredFragments
        : current.collectedFragments
              .clamp(0, current.requiredFragments)
              .toInt();
    final nextCount = alreadyOwned
        ? current.requiredFragments
        : (previous + fragmentAmount)
              .clamp(0, current.requiredFragments)
              .toInt();
    final didUnlock =
        !alreadyOwned &&
        previous < current.requiredFragments &&
        nextCount >= current.requiredFragments;

    UserCosmetic? unlockedCosmetic;
    if (didUnlock) {
      unlockedCosmetic = _buildUnlockedCosmetic(
        itemId: item.id,
        sourceType: 'daily_run_fragment',
        sourceEvent: _normalizedFragmentKey(fragmentName),
        now: now,
      );
      inventory.add(unlockedCosmetic);
      await _saveInventoryLocally(inventory);
    }

    final updated = CosmeticFragmentProgress(
      itemId: item.id,
      collectedFragments: nextCount,
      requiredFragments: current.requiredFragments,
      updatedAt: now,
      unlockedAt: didUnlock
          ? now
          : alreadyOwned
          ? current.unlockedAt ?? now
          : current.unlockedAt,
    );
    progressMap[item.id] = updated;
    await _saveFragmentProgressMap(progressMap);

    return DailyRunCosmeticGrantResult(
      item: item,
      progress: updated,
      previousFragments: previous,
      didUnlock: didUnlock,
      unlockedCosmetic: unlockedCosmetic,
    );
  }

  Future<List<CosmeticFragmentProgress>> loadFragmentProgress() async {
    final map = await _loadFragmentProgressMap();
    return map.values.toList(growable: false);
  }

  Future<bool> ownsItemLocally(String itemId) async {
    final inventory = await _loadInventoryLocally();
    return inventory.any((entry) => entry.itemId == itemId);
  }

  CosmeticItem dailyRunItemForFragment(String fragmentName) {
    final itemId = dailyRunItemIdForFragment(fragmentName);
    return getCatalog().firstWhere((item) => item.id == itemId);
  }

  String dailyRunItemIdForFragment(String fragmentName) {
    final normalized = _normalizedFragmentKey(fragmentName);
    if (normalized.contains('neon') || normalized.contains('burst')) {
      return 'effect_neon_number_burst';
    }
    if (normalized.contains('comet') || normalized.contains('frame')) {
      return 'frame_comet';
    }
    return 'effect_nova_trail';
  }

  Future<Map<String, CosmeticFragmentProgress>>
  _loadFragmentProgressMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_fragmentProgressKey);
      if (raw == null || raw.isEmpty) {
        return {};
      }
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return {
          for (final entry in decoded)
            if (entry is Map)
              _fragmentProgressFromMap(entry).itemId: _fragmentProgressFromMap(
                entry,
              ),
        };
      }
    } catch (e) {
      debugPrint('[CosmeticsService] load fragment progress failed: $e');
    }
    return {};
  }

  CosmeticFragmentProgress _fragmentProgressFromMap(
    Map<dynamic, dynamic> entry,
  ) {
    return CosmeticFragmentProgress.fromJson(Map<String, dynamic>.from(entry));
  }

  Future<void> _saveFragmentProgressMap(
    Map<String, CosmeticFragmentProgress> progress,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = progress.values.map((entry) => entry.toJson()).toList();
      await prefs.setString(_fragmentProgressKey, jsonEncode(items));
    } catch (e) {
      debugPrint('[CosmeticsService] save fragment progress failed: $e');
    }
  }

  // ────────────────────── UNLOCK ITEM ────────────────────────────

  /// Grants the user a cosmetic item (called by unlock triggers).
  Future<UserCosmetic?> unlockItem({
    required String itemId,
    required String sourceType,
    String? sourceEvent,
  }) async {
    final userId = AuthService.instance.userId ?? 'local';
    final now = DateTime.now();
    final newItem = UserCosmetic(
      id: '${userId}_${itemId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      itemId: itemId,
      unlockedAt: now,
      sourceType: sourceType,
      sourceEvent: sourceEvent,
    );

    // Persist locally first
    final current = await _loadInventoryLocally();
    final alreadyOwned = current.any((c) => c.itemId == itemId);
    if (alreadyOwned) return null;
    current.add(newItem);
    await _saveInventoryLocally(current);

    // Try server
    try {
      final client = AuthService.instance.client;
      await client.post(
        '/api/cosmetics/purchase',
        data: {
          'cosmeticItemId': itemId,
          'sourceType': sourceType,
          'sourceEvent': sourceEvent,
        },
      );
    } catch (e) {
      debugPrint('[CosmeticsService] unlock server call failed: $e');
    }
    return newItem;
  }

  /// Equips the cosmetic item matching [fragmentName] into the correct
  /// [UserAvatar] slot and persists locally. No backend call — sync happens
  /// the next time the user saves their avatar via [updateAvatarConfig].
  ///
  /// Slot mapping:
  ///   `frame_*`  → [UserAvatar.frameId]
  ///   `effect_*` → [UserAvatar.animatedEffectId]
  ///   anything else → [UserAvatar.accessoryId]
  Future<void> equipItem(String fragmentName) async {
    final itemId = dailyRunItemIdForFragment(fragmentName);
    final userId = AuthService.instance.userId ?? 'local';
    final current = await _loadAvatarLocally(userId);

    final UserAvatar updated;
    if (itemId.startsWith('frame_')) {
      updated = current.copyWith(frameId: itemId);
    } else if (itemId.startsWith('effect_')) {
      updated = current.copyWith(animatedEffectId: itemId);
    } else if (itemId.startsWith('acc_')) {
      updated = current.copyWith(accessoryId: itemId);
    } else {
      updated = current.copyWith(accessoryId: itemId);
    }

    await _saveAvatarLocally(updated);
  }

  UserCosmetic _buildUnlockedCosmetic({
    required String itemId,
    required String sourceType,
    required DateTime now,
    String? sourceEvent,
  }) {
    final userId = AuthService.instance.userId ?? 'local';
    return UserCosmetic(
      id: '${userId}_${itemId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      itemId: itemId,
      unlockedAt: now,
      sourceType: sourceType,
      sourceEvent: sourceEvent,
    );
  }

  String _normalizedFragmentKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(' fragment', '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  // ─────────────────────── STATIC CATALOG ────────────────────────

  List<CosmeticItem> _buildCatalog() {
    final now = DateTime(2026, 1, 1);
    return [
      // ── SKINS ──
      CosmeticItem(
        id: 'skin_default',
        name: 'Defaultna koža',
        category: CosmeticCategory.avatarSkin,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Startni predmet',
        assetKey: 'skin_default',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'skin_golden',
        name: 'Zlatna koža',
        category: CosmeticCategory.avatarSkin,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Dostignuti nivo 10',
        assetKey: 'skin_golden',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'skin_galaxy',
        name: 'Galaktička koža',
        category: CosmeticCategory.avatarSkin,
        rarity: CosmeticRarity.epic,
        unlockCondition: 'Dostignuti nivo 25',
        assetKey: 'skin_galaxy',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'skin_neon',
        name: 'Neon koža',
        category: CosmeticCategory.avatarSkin,
        rarity: CosmeticRarity.legendary,
        unlockCondition: 'Završi Math Olympiad Season',
        assetKey: 'skin_neon',
        seasonId: 'season_olympiad_2026',
        isLimited: true,
        createdAt: now,
      ),

      // ── HAIR ──
      CosmeticItem(
        id: 'hair_default',
        name: 'Kratka kosa',
        category: CosmeticCategory.hairStyle,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Startni predmet',
        assetKey: 'hair_default',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'hair_curly',
        name: 'Kovrčava kosa',
        category: CosmeticCategory.hairStyle,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Dostignuti nivo 3',
        assetKey: 'hair_curly',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'hair_long',
        name: 'Duga kosa',
        category: CosmeticCategory.hairStyle,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Dostignuti nivo 5',
        assetKey: 'hair_long',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'hair_mohawk',
        name: 'Mohawk',
        category: CosmeticCategory.hairStyle,
        rarity: CosmeticRarity.rare,
        unlockCondition: '14-dnevni streak',
        assetKey: 'hair_mohawk',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'hair_afro',
        name: 'Afro',
        category: CosmeticCategory.hairStyle,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Dostignuti nivo 15',
        assetKey: 'hair_afro',
        createdAt: now,
      ),

      // ── CLOTHING ──
      CosmeticItem(
        id: 'clothing_default',
        name: 'Školska uniforma',
        category: CosmeticCategory.clothing,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Startni predmet',
        assetKey: 'clothing_default',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'clothing_hoodie',
        name: 'Hoodie',
        category: CosmeticCategory.clothing,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Dostignuti nivo 7',
        assetKey: 'clothing_hoodie',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'clothing_scifi',
        name: 'Sci-Fi odijelo',
        category: CosmeticCategory.clothing,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Dostignuti nivo 20',
        assetKey: 'clothing_scifi',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'clothing_champion',
        name: 'Šampionska jakna',
        category: CosmeticCategory.clothing,
        rarity: CosmeticRarity.epic,
        unlockCondition: 'Top 10 ljestvice škola',
        assetKey: 'clothing_champion',
        createdAt: now,
      ),

      // ── ACCESSORIES ──
      CosmeticItem(
        id: 'acc_graduation_cap',
        name: 'Magistarska kapa',
        category: CosmeticCategory.accessory,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Osvoji 5 bedževa',
        assetKey: 'acc_graduation_cap',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'acc_vr_goggles',
        name: 'VR Naočale',
        category: CosmeticCategory.accessory,
        rarity: CosmeticRarity.epic,
        unlockCondition: 'Dostignuti nivo 30',
        assetKey: 'acc_vr_goggles',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'acc_math_crown',
        name: 'Matematička kruna',
        category: CosmeticCategory.accessory,
        rarity: CosmeticRarity.legendary,
        unlockCondition: '#1 na globalnoj ljestvici',
        assetKey: 'acc_math_crown',
        isLimited: false,
        createdAt: now,
      ),

      // ── EMOJI REACTIONS ──
      CosmeticItem(
        id: 'emoji_default',
        name: '👍 Standardni emoji',
        category: CosmeticCategory.emojiReaction,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Startni predmet',
        assetKey: '👍',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'emoji_fire',
        name: '🔥 Streak plamen',
        category: CosmeticCategory.emojiReaction,
        rarity: CosmeticRarity.rare,
        unlockCondition: '7-dnevni streak',
        assetKey: '🔥',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'emoji_brain',
        name: '🧠 Genije',
        category: CosmeticCategory.emojiReaction,
        rarity: CosmeticRarity.epic,
        unlockCondition: '95% tačnost u sesiji',
        assetKey: '🧠',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'emoji_lightning',
        name: '⚡ Brzina',
        category: CosmeticCategory.emojiReaction,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Odgovori u prvih 3 sekunde 10 puta',
        assetKey: '⚡',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'emoji_trophy',
        name: '🏆 Trofej',
        category: CosmeticCategory.emojiReaction,
        rarity: CosmeticRarity.legendary,
        unlockCondition: 'Pobijedi u školskom takmičenju',
        assetKey: '🏆',
        createdAt: now,
      ),

      // ── FRAMES ──
      CosmeticItem(
        id: 'frame_silver',
        name: 'Srebrni okvir',
        category: CosmeticCategory.avatarFrame,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Dostignuti nivo 5',
        assetKey: 'frame_silver',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'frame_comet',
        name: 'Comet Frame',
        category: CosmeticCategory.avatarFrame,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Collect 5 Comet Frame fragments from Daily Run',
        assetKey: 'frame_comet',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'frame_blue_glow',
        name: 'Plavi sjaj',
        category: CosmeticCategory.avatarFrame,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Dostignuti nivo 12',
        assetKey: 'frame_blue_glow',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'frame_streak_flame',
        name: 'Streak plamen okvir',
        category: CosmeticCategory.avatarFrame,
        rarity: CosmeticRarity.rare,
        unlockCondition: '30-dnevni streak',
        assetKey: 'frame_streak_flame',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'frame_gold_laurel',
        name: 'Zlatni lovorov vijenac',
        category: CosmeticCategory.avatarFrame,
        rarity: CosmeticRarity.legendary,
        unlockCondition: 'Top 3 na sedmičnoj ljestvici',
        assetKey: 'frame_gold_laurel',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'frame_olympiad',
        name: 'Olimpijada okvir',
        category: CosmeticCategory.avatarFrame,
        rarity: CosmeticRarity.mythic,
        unlockCondition: 'Završi Math Olympiad Season track',
        assetKey: 'frame_olympiad',
        seasonId: 'season_olympiad_2026',
        isLimited: true,
        createdAt: now,
      ),

      // ── BACKGROUNDS ──
      CosmeticItem(
        id: 'bg_default',
        name: 'Standardna pozadina',
        category: CosmeticCategory.profileBackground,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Startni predmet',
        assetKey: 'bg_default',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'bg_galaxy',
        name: 'Galaksija',
        category: CosmeticCategory.profileBackground,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Dostignuti nivo 18',
        assetKey: 'bg_galaxy',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'bg_chalkboard',
        name: 'Tabla',
        category: CosmeticCategory.profileBackground,
        rarity: CosmeticRarity.common,
        unlockCondition: 'Dostignuti nivo 8',
        assetKey: 'bg_chalkboard',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'bg_circuit',
        name: 'Električna ploča',
        category: CosmeticCategory.profileBackground,
        rarity: CosmeticRarity.epic,
        unlockCondition: 'Dostignuti nivo 40',
        assetKey: 'bg_circuit',
        createdAt: now,
      ),

      // â”€â”€ DAILY RUN EFFECTS â”€â”€
      CosmeticItem(
        id: 'effect_nova_trail',
        name: 'Nova Trail',
        category: CosmeticCategory.animatedEffect,
        rarity: CosmeticRarity.rare,
        unlockCondition: 'Collect 5 Nova Trail fragments from Daily Run',
        assetKey: 'effect_nova_trail',
        createdAt: now,
      ),
      CosmeticItem(
        id: 'effect_neon_number_burst',
        name: 'Neon Number Burst',
        category: CosmeticCategory.animatedEffect,
        rarity: CosmeticRarity.epic,
        unlockCondition: 'Collect 5 Neon Number Burst fragments from Daily Run',
        assetKey: 'effect_neon_number_burst',
        createdAt: now,
      ),
    ];
  }
}
