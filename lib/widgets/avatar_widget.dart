import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_avatar.dart';
import '../state/avatar_provider.dart';
import 'cosmetic_visuals.dart';

/// Renders a user's avatar with equipped cosmetic items.
///
/// Uses icon/color-based rendering — no external asset images needed.
/// Fully reactive: rebuilds when [AvatarProvider] changes.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.size = 72,
    this.showFrame = true,
    this.overrideConfig,
    this.borderColor,
  });

  /// Diameter of the avatar in logical pixels.
  final double size;

  /// Whether to render the avatar frame (border decoration).
  final bool showFrame;

  /// Optionally override the config (e.g., for live preview in customisation screen).
  final UserAvatar? overrideConfig;

  /// Fallback border color shown when no frame is equipped.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AvatarProvider>();
    final config = overrideConfig ?? provider.avatarConfig;

    if (config == null) {
      return _PlaceholderAvatar(size: size, borderColor: borderColor);
    }

    return _AvatarBody(
      config: config,
      size: size,
      showFrame: showFrame,
      borderColor: borderColor,
    );
  }
}

// ─── Internal Avatar Body ───────────────────────────────────────────────────

class _AvatarBody extends StatelessWidget {
  const _AvatarBody({
    required this.config,
    required this.size,
    required this.showFrame,
    this.borderColor,
  });

  final UserAvatar config;
  final double size;
  final bool showFrame;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final padding = showFrame ? size * 0.06 : 0.0;
    final innerSize = size - padding * 2;

    Widget avatar = _buildAvatarFace(innerSize);

    if (showFrame) {
      final frameDecoration = CosmeticVisuals.frameDecoration(
        config.frameId,
        size,
        fallbackColor: borderColor,
      );
      avatar = Container(
        width: size,
        height: size,
        decoration: frameDecoration,
        padding: EdgeInsets.all(padding),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatarFace(double innerSize) {
    final skinColor = CosmeticVisuals.skinColor(config.skinId);
    final hairColor = CosmeticVisuals.hairColor(config.hairId);
    final clothingColor = CosmeticVisuals.clothingColor(config.clothingId);
    final hairIcon = CosmeticVisuals.hairIcon(config.hairId);

    return SizedBox(
      width: innerSize,
      height: innerSize,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Base circle (face + body)
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: skinColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Clothing strip at bottom
                Container(
                  height: innerSize * 0.30,
                  decoration: BoxDecoration(
                    color: clothingColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(innerSize / 2),
                      bottomRight: Radius.circular(innerSize / 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Face features
          Positioned.fill(
            child: CustomPaint(
              painter: _FacePainter(skinColor: skinColor),
            ),
          ),
          // Hair icon at top
          Positioned(
            top: innerSize * 0.04,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                hairIcon,
                color: hairColor,
                size: innerSize * 0.32,
              ),
            ),
          ),
          // Accessory
          if (config.accessoryId != null)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                CosmeticVisuals.accessoryIcon(config.accessoryId),
                color: Colors.amber,
                size: innerSize * 0.30,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Face Painter ───────────────────────────────────────────────────────────

class _FacePainter extends CustomPainter {
  final Color skinColor;

  _FacePainter({required this.skinColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.5;
    final r = size.width * 0.12;

    final eyePaint = Paint()..color = const Color(0xFF333333);
    final mouthPaint = Paint()
      ..color = const Color(0xFF555555)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;

    // Eyes
    canvas.drawCircle(Offset(cx - r * 1.1, cy), r * 0.45, eyePaint);
    canvas.drawCircle(Offset(cx + r * 1.1, cy), r * 0.45, eyePaint);

    // Smile
    final path = Path()
      ..moveTo(cx - r * 0.8, cy + r * 1.0)
      ..quadraticBezierTo(cx, cy + r * 1.8, cx + r * 0.8, cy + r * 1.0);
    canvas.drawPath(path, mouthPaint);
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.skinColor != skinColor;
}

// ─── Placeholder ────────────────────────────────────────────────────────────

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.size, this.borderColor});

  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5), width: size * 0.025),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.55,
        color: color.withOpacity(0.6),
      ),
    );
  }
}
