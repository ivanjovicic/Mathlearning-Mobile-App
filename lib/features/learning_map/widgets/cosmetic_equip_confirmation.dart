import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_fragment_card.dart';

// ---------------------------------------------------------------------------
// One-shot radial sparkle burst.
// ---------------------------------------------------------------------------
class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.color, required this.t});

  final Color color;
  final double t; // 0..1 (forward only)

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.46;
    const count = 12;

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final r = maxR * t;
      final alpha = (1.0 - t).clamp(0.0, 1.0);

      // Primary dot.
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * r,
        (4.5 * (1.0 - t * 0.55)).clamp(0.8, 4.5),
        Paint()..color = color.withValues(alpha: alpha * 0.95),
      );

      // Smaller white echo at a slightly different angle & radius.
      if (t > 0.18) {
        final r2 = maxR * (t - 0.18) * 1.25;
        final a2 = angle + math.pi / count;
        canvas.drawCircle(
          center + Offset(math.cos(a2), math.sin(a2)) * r2,
          (2.8 * (1.0 - t * 0.6)).clamp(0.5, 2.8),
          Paint()..color = Colors.white.withValues(alpha: alpha * 0.65),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// CosmeticEquipConfirmation
//
// Shows the one-shot sparkle burst + "Equipped!" text + item subtitle.
// Calls [onDone] automatically after the animation completes + a short hold.
// Drop this widget into the celebration dialog in place of the CTAs.
// ---------------------------------------------------------------------------
class CosmeticEquipConfirmation extends StatefulWidget {
  const CosmeticEquipConfirmation({
    super.key,
    required this.itemName,
    required this.itemType,
    required this.rarityColor,
    this.onDone,
  });

  /// The cosmetic item name (without " Fragment"), e.g. "Nova Trail".
  final String itemName;

  /// Visual type, used to derive the short "active" description.
  final CosmeticItemType itemType;

  /// Accent colour matching the item rarity.
  final Color rarityColor;

  /// Called automatically after the animation + hold period finishes (~1.5 s).
  final VoidCallback? onDone;

  @override
  State<CosmeticEquipConfirmation> createState() =>
      _CosmeticEquipConfirmationState();
}

class _CosmeticEquipConfirmationState extends State<CosmeticEquipConfirmation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstCtrl;

  @override
  void initState() {
    super.initState();
    _burstCtrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 800),
          )
          ..forward().whenComplete(() {
            // Hold the "Equipped!" text for a beat before handing control back.
            Future<void>.delayed(const Duration(milliseconds: 650), () {
              if (mounted) widget.onDone?.call();
            });
          });
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  String get _typeLabel => switch (widget.itemType) {
    CosmeticItemType.trail => 'trail effect',
    CosmeticItemType.frame => 'avatar frame',
    CosmeticItemType.avatar => 'avatar gear',
    CosmeticItemType.burst => 'answer effect',
    CosmeticItemType.generic => 'cosmetic',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 136,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Burst layer.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _burstCtrl,
                builder: (_, _) => CustomPaint(
                  painter: _BurstPainter(
                    color: widget.rarityColor,
                    t: _burstCtrl.value,
                  ),
                ),
              ),
            ),
          ),

          // Text content.
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: widget.rarityColor,
                size: 42,
              ),

              const SizedBox(height: 8),

              Text(
                'Equipped!',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: widget.rarityColor,
                  shadows: [
                    Shadow(
                      color: widget.rarityColor.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${widget.itemName} is now active',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: widget.rarityColor.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _typeLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: widget.rarityColor.withValues(alpha: 0.45),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
