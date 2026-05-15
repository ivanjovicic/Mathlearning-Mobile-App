import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cosmetic_target.dart';

class CosmeticTargetService {
  CosmeticTargetService._();

  static final CosmeticTargetService instance = CosmeticTargetService._();

  static const _storagePrefix = 'cosmetic_target_state_v1.';

  Future<CosmeticTarget?> loadTarget({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(userId));
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final target = CosmeticTarget.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (target.targetCosmeticItemId.isEmpty) return null;
      return target;
    } catch (e) {
      debugPrint('[CosmeticTargetService] load target failed: $e');
      return null;
    }
  }

  Future<void> saveTarget(CosmeticTarget target, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey(userId), jsonEncode(target.toJson()));
    } catch (e) {
      debugPrint('[CosmeticTargetService] save target failed: $e');
    }
  }

  Future<void> clearTarget({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(userId));
    } catch (e) {
      debugPrint('[CosmeticTargetService] clear target failed: $e');
    }
  }

  String _storageKey(String? userId) {
    final safeUserId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    return '$_storagePrefix$safeUserId';
  }
}
