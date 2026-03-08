import 'package:flutter/material.dart';
import '../models/cosmetic_item.dart';

/// Visual helpers for rendering cosmetic items.
class CosmeticVisuals {
  CosmeticVisuals._();

  // ─── Rarity Colors ────────────────────────────────────────────

  static Color rarityColor(CosmeticRarity rarity) {
    switch (rarity) {
      case CosmeticRarity.common:
        return const Color(0xFF9E9E9E);
      case CosmeticRarity.rare:
        return const Color(0xFF2196F3);
      case CosmeticRarity.epic:
        return const Color(0xFF9C27B0);
      case CosmeticRarity.legendary:
        return const Color(0xFFFF9800);
      case CosmeticRarity.mythic:
        return const Color(0xFFE91E63);
    }
  }

  static LinearGradient? rarityGradient(CosmeticRarity rarity) {
    switch (rarity) {
      case CosmeticRarity.mythic:
        return const LinearGradient(
          colors: [
            Color(0xFFE91E63),
            Color(0xFF9C27B0),
            Color(0xFF2196F3),
            Color(0xFF4CAF50),
          ],
        );
      case CosmeticRarity.legendary:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFD600)],
        );
      default:
        return null;
    }
  }

  // ─── Skin Colors ──────────────────────────────────────────────

  static Color skinColor(String? skinId) {
    switch (skinId) {
      case 'skin_golden':
        return const Color(0xFFFFD700);
      case 'skin_galaxy':
        return const Color(0xFF1A1A2E);
      case 'skin_neon':
        return const Color(0xFF00E5FF);
      default:
        return const Color(0xFFFFCC99);
    }
  }

  // ─── Hair Colors ──────────────────────────────────────────────

  static Color hairColor(String? hairId) {
    switch (hairId) {
      case 'hair_curly':
        return const Color(0xFF4E342E);
      case 'hair_long':
        return const Color(0xFFFFEB3B);
      case 'hair_mohawk':
        return const Color(0xFFE53935);
      case 'hair_afro':
        return const Color(0xFF212121);
      default:
        return const Color(0xFF5D4037);
    }
  }

  // ─── Clothing Colors ─────────────────────────────────────────

  static Color clothingColor(String? clothingId) {
    switch (clothingId) {
      case 'clothing_hoodie':
        return const Color(0xFF37474F);
      case 'clothing_scifi':
        return const Color(0xFF00BCD4);
      case 'clothing_champion':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF1565C0);
    }
  }

  // ─── Frame Border ─────────────────────────────────────────────

  static BoxDecoration frameDecoration(
    String? frameId,
    double size, {
    Color? fallbackColor,
  }) {
    switch (frameId) {
      case 'frame_gold_laurel':
        return BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        );
      case 'frame_olympiad':
        return BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE91E63),
              Color(0xFF9C27B0),
              Color(0xFF2196F3),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          ],
        );
      case 'frame_blue_glow':
        return BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF2196F3),
            width: size * 0.04,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        );
      case 'frame_streak_flame':
        return BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFF5722),
            width: size * 0.04,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5722).withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        );
      case 'frame_silver':
        return BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF9E9E9E),
            width: size * 0.035,
          ),
        );
      default:
        return BoxDecoration(
          shape: BoxShape.circle,
          border: fallbackColor != null
              ? Border.all(color: fallbackColor, width: size * 0.025)
              : null,
        );
    }
  }

  // ─── Background Gradient ─────────────────────────────────────

  static BoxDecoration backgroundDecoration(
    String? backgroundId,
    BorderRadius borderRadius,
  ) {
    switch (backgroundId) {
      case 'bg_galaxy':
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: const LinearGradient(
            colors: [Color(0xFF0D0D2B), Color(0xFF1A237E), Color(0xFF311B92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'bg_chalkboard':
        return BoxDecoration(
          borderRadius: borderRadius,
          color: const Color(0xFF1B5E20),
        );
      case 'bg_circuit':
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            colors: [const Color(0xFF0A0A0A), const Color(0xFF00E5FF).withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      default:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
    }
  }

  // ─── Hair Shape ───────────────────────────────────────────────

  static IconData hairIcon(String? hairId) {
    switch (hairId) {
      case 'hair_curly':
        return Icons.auto_awesome;
      case 'hair_long':
        return Icons.spa;
      case 'hair_mohawk':
        return Icons.flash_on;
      case 'hair_afro':
        return Icons.cloud;
      default:
        return Icons.person;
    }
  }

  // ─── Accessory Icon ───────────────────────────────────────────

  static IconData accessoryIcon(String? accId) {
    switch (accId) {
      case 'acc_graduation_cap':
        return Icons.school;
      case 'acc_vr_goggles':
        return Icons.view_in_ar;
      case 'acc_math_crown':
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }
}
