import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Rarity tier for a cosmetic fragment, used to drive color and glow.
enum FragmentRarity { common, rare, epic, legendary }

extension _FragmentRarityX on FragmentRarity {
  Color color(ColorScheme colors) {
    return switch (this) {
      FragmentRarity.common => colors.secondary,
      FragmentRarity.rare => colors.primary,
      FragmentRarity.epic => colors.tertiary,
      FragmentRarity.legendary => const Color(0xFFFFB800),
    };
  }

  String get label {
    return switch (this) {
      FragmentRarity.common => 'Common',
      FragmentRarity.rare => 'Rare',
      FragmentRarity.epic => 'Epic',
      FragmentRarity.legendary => 'Legendary',
    };
  }

  double get _glowBlur => switch (this) {
    FragmentRarity.common => 18.0,
    FragmentRarity.rare => 28.0,
    FragmentRarity.epic => 36.0,
    FragmentRarity.legendary => 44.0,
  };

  double get _glowSpread => switch (this) {
    FragmentRarity.common => 1.0,
    FragmentRarity.rare => 3.0,
    FragmentRarity.epic => 5.0,
    FragmentRarity.legendary => 7.0,
  };
}

// ---------------------------------------------------------------------------
// Item-type inference — maps fragment name keywords to a cosmetic category.
// ---------------------------------------------------------------------------
enum CosmeticItemType { trail, frame, avatar, burst, generic }

CosmeticItemType cosmeticItemType(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('trail') || lower.contains('path')) return CosmeticItemType.trail;
  if (lower.contains('frame') || lower.contains('border')) return CosmeticItemType.frame;
  if (lower.contains('avatar') || lower.contains('skin') || lower.contains('char')) {
    return CosmeticItemType.avatar;
  }
  if (lower.contains('burst') || lower.contains('glow') || lower.contains('aura') ||
      lower.contains('nova') || lower.contains('neon')) {
    return CosmeticItemType.burst;
  }
  return CosmeticItemType.generic;
}

/// Shows a cosmetic fragment with rarity glow, spin-in animation, and
/// collection progress ("2/5 collected").
///
/// When [collected] >= [total] the card switches to a completion state:
/// a stronger glow, repeating shimmer celebration, and an optional
/// "View collection" button (shown when [onViewCollection] is provided).
class CosmeticFragmentCard extends StatelessWidget {
  const CosmeticFragmentCard({
    super.key,
    required this.fragmentName,
    required this.collected,
    required this.total,
    this.rarity = FragmentRarity.rare,
    this.icon = Icons.auto_awesome_rounded,
    this.animate = true,
    this.heading = 'Fragment found!',
    this.onViewCollection,
    this.onEquipNow,
  });

  final String fragmentName;
  final int collected;
  final int total;
  final FragmentRarity rarity;
  final IconData icon;
  final bool animate;
  final String heading;
  final VoidCallback? onViewCollection;

  /// Called when the user taps "Equip now" after the item is fully unlocked.
  final VoidCallback? onEquipNow;

  bool get _isCompleted => collected >= total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rarityColor = rarity.color(colors);

    Widget card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: rarityColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rarityColor.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.30),
            blurRadius: rarity._glowBlur,
            spreadRadius: rarity._glowSpread,
          ),
          if (rarity.index >= FragmentRarity.epic.index)
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.15),
              blurRadius: rarity._glowBlur * 1.8,
              spreadRadius: 0,
            ),
          // Stronger outer glow when all fragments collected.
          if (_isCompleted)
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.28),
              blurRadius: rarity._glowBlur * 2.4,
              spreadRadius: rarity._glowSpread + 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual preview hero — flush with card top corners.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CosmeticPreviewHero(
              rarity: rarity,
              fragmentName: fragmentName,
              isCompleted: _isCompleted,
              animate: animate,
            ),
          ),
          // Info section.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading,
                            style: textTheme.labelMedium?.copyWith(
                              color: rarityColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fragmentName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _ProgressPips(
                            collected: collected,
                            total: total,
                            color: rarityColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rarity badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _isCompleted ? 'Unlocked' : rarity.label,
                        style: textTheme.labelSmall?.copyWith(
                          color: rarityColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isCompleted && (onEquipNow != null || onViewCollection != null)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (onEquipNow != null) ...[                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onEquipNow,
                            icon: const Icon(Icons.checkroom_rounded, size: 16),
                            label: const Text('Equip now'),
                            style: FilledButton.styleFrom(
                              backgroundColor: rarityColor,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                        if (onViewCollection != null) const SizedBox(width: 8),
                      ],
                      if (onViewCollection != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onViewCollection,
                            icon: const Icon(Icons.collections_bookmark_rounded, size: 16),
                            label: const Text('View collection'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: rarityColor,
                              side: BorderSide(color: rarityColor.withValues(alpha: 0.55)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (animate) {
      card = card
          .animate()
          .fadeIn(duration: 240.ms)
          .slideY(begin: 0.18, end: 0, duration: 300.ms, curve: Curves.easeOutBack)
          .shimmer(
            duration: 900.ms,
            color: rarityColor.withValues(alpha: 0.22),
            delay: 200.ms,
          );

      if (_isCompleted) {
        // Celebration: repeating golden shimmer after the reveal.
        card = card
            .animate(
              delay: 600.ms,
              onPlay: (c) => c.repeat(period: 2400.ms, reverse: true),
            )
            .shimmer(
              duration: 1200.ms,
              color: rarityColor.withValues(alpha: 0.20),
            );
      }
    }

    return card;
  }
}

// ---------------------------------------------------------------------------
// Preview hero — StatefulWidget so each type can drive its own loop.
// ---------------------------------------------------------------------------
class CosmeticPreviewHero extends StatefulWidget {
  const CosmeticPreviewHero({
    super.key,
    required this.rarity,
    required this.fragmentName,
    required this.isCompleted,
    required this.animate,
  });

  final FragmentRarity rarity;
  final String fragmentName;
  final bool isCompleted;
  final bool animate;

  @override
  State<CosmeticPreviewHero> createState() => _CosmeticPreviewHeroState();
}

class _CosmeticPreviewHeroState extends State<CosmeticPreviewHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rarityColor = widget.rarity.color(colors);
    final itemType = cosmeticItemType(widget.fragmentName);

    Widget preview = Container(
      width: double.infinity,
      height: 96,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rarityColor.withValues(alpha: 0.20),
            rarityColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: switch (itemType) {
              CosmeticItemType.trail => _TrailPreview(
                  color: rarityColor,
                  progress: _ctrl,
                  rarity: widget.rarity,
                ),
              CosmeticItemType.frame => _FramePreview(
                  color: rarityColor,
                  progress: _ctrl,
                  rarity: widget.rarity,
                ),
              CosmeticItemType.avatar => _AvatarGearPreview(
                  color: rarityColor,
                  progress: _ctrl,
                ),
              CosmeticItemType.burst => _BurstPreview(
                  color: rarityColor,
                  progress: _ctrl,
                ),
              CosmeticItemType.generic => _GenericPreview(
                  color: rarityColor,
                  rarity: widget.rarity,
                ),
            },
          ),
          if (widget.isCompleted)
            Positioned(
              top: 8,
              right: 10,
              child: _UnlockedBadge(color: rarityColor),
            ),
        ],
      ),
    );

    if (widget.animate && widget.isCompleted) {
      preview = preview
          .animate(
            onPlay: (c) => c.repeat(period: 2400.ms, reverse: true),
          )
          .shimmer(
            duration: 1200.ms,
            color: rarityColor.withValues(alpha: 0.28),
          );
    }

    return preview;
  }
}

// ---------------------------------------------------------------------------
// Trail preview — glowing ball travels an S-curve path left to right.
// ---------------------------------------------------------------------------
class _TrailPreview extends StatelessWidget {
  const _TrailPreview({
    required this.color,
    required this.progress,
    required this.rarity,
  });

  final Color color;
  final Animation<double> progress;
  final FragmentRarity rarity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, _) => CustomPaint(
        painter: _TrailPainter(color: color, t: progress.value, rarity: rarity),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter({
    required this.color,
    required this.t,
    required this.rarity,
  });

  final Color color;
  final double t;
  final FragmentRarity rarity;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(
        size.width * 0.25, size.height * 0.15,
        size.width * 0.75, size.height * 0.85,
        size.width, size.height * 0.5,
      );

    // Faint base path line.
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final metric = path.computeMetrics().first;
    final len = metric.length;

    // Ghost trail behind the ball.
    for (var i = 6; i >= 1; i--) {
      final trailT = (t - i * 0.035).clamp(0.0, 1.0);
      final tang = metric.getTangentForOffset(len * trailT);
      if (tang == null) continue;
      canvas.drawCircle(
        tang.position,
        9.0 - i * 1.0,
        Paint()
          ..color = color.withValues(alpha: 0.06 * i)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Main ball.
    final tang = metric.getTangentForOffset(len * t);
    if (tang == null) return;
    final pos = tang.position;
    final glowBlur = rarity._glowBlur * 0.8;

    canvas.drawCircle(
      pos, 18,
      Paint()
        ..color = color.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlur),
    );
    canvas.drawCircle(pos, 8, Paint()..color = color);
    canvas.drawCircle(pos, 4, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Frame preview — pulsing glowing ring around an avatar silhouette.
// ---------------------------------------------------------------------------
class _FramePreview extends StatelessWidget {
  const _FramePreview({
    required this.color,
    required this.progress,
    required this.rarity,
  });

  final Color color;
  final Animation<double> progress;
  final FragmentRarity rarity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, _) {
        final pulse = math.sin(progress.value * 2 * math.pi) * 0.5 + 0.5;
        final borderWidth = 3.0 + pulse * 2.0;
        final glowRadius = rarity._glowBlur * (0.7 + pulse * 0.6);
        final glowSpread = rarity._glowSpread * (0.5 + pulse * 0.8);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring.
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.35 + pulse * 0.45),
                    width: borderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28 + pulse * 0.32),
                      blurRadius: glowRadius,
                      spreadRadius: glowSpread,
                    ),
                  ],
                ),
              ),
              // Second outer ring for epic/legendary.
              if (rarity.index >= FragmentRarity.epic.index)
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.12 + pulse * 0.18),
                      width: 1.5,
                    ),
                  ),
                ),
              Icon(Icons.person_rounded,
                  color: color.withValues(alpha: 0.75), size: 40),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar gear preview — person silhouette with glowing gear badge.
// ---------------------------------------------------------------------------
class _AvatarGearPreview extends StatelessWidget {
  const _AvatarGearPreview({
    required this.color,
    required this.progress,
  });

  final Color color;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, _) {
        final pulse = math.sin(progress.value * 2 * math.pi) * 0.5 + 0.5;
        return Center(
          child: SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.14 + pulse * 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28 + pulse * 0.22),
                        blurRadius: 14 + pulse * 10,
                      ),
                    ],
                  ),
                  child: Icon(Icons.person_rounded,
                      color: color.withValues(alpha: 0.80), size: 40),
                ),
                // Gear badge — top-right corner.
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45 + pulse * 0.35),
                          blurRadius: 8 + pulse * 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Burst preview — expanding concentric rings + check mark (answer effect).
// ---------------------------------------------------------------------------
class _BurstPreview extends StatelessWidget {
  const _BurstPreview({
    required this.color,
    required this.progress,
  });

  final Color color;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, _) => CustomPaint(
        painter: _BurstPainter(color: color, t: progress.value),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide * 0.46;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = maxRadius * phase;
      final alpha = (1.0 - phase).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        radius,
        ringPaint..color = color.withValues(alpha: alpha * 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Generic fallback preview — static glow blob + icon.
// ---------------------------------------------------------------------------
class _GenericPreview extends StatelessWidget {
  const _GenericPreview({required this.color, required this.rarity});

  final Color color;
  final FragmentRarity rarity;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.40),
              blurRadius: rarity._glowBlur * 1.2,
              spreadRadius: rarity._glowSpread,
            ),
          ],
        ),
        child: Icon(Icons.auto_awesome_rounded, color: color, size: 32),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unlocked badge — shared corner label.
// ---------------------------------------------------------------------------
class _UnlockedBadge extends StatelessWidget {
  const _UnlockedBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.50), blurRadius: 8),
        ],
      ),
      child: const Text(
        'Unlocked!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProgressPips extends StatelessWidget {
  const _ProgressPips({
    required this.collected,
    required this.total,
    required this.color,
  });

  final int collected;
  final int total;
  final Color color;

  bool get _isComplete => collected >= total;
  int get _remaining => total - collected;

  /// True when ≥60% of fragments are collected and the set is not yet complete.
  bool get _isClose => !_isComplete && collected * 100 ~/ total >= 60;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prominent "Almost there!" when ≥60% collected.
        if (_isClose)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Almost there!',
              style: textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ),
        // Pips row + "X/Y collected" count.
        Row(
          children: [
            for (var i = 1; i <= total; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= collected
                      ? color
                      : color.withValues(alpha: 0.22),
                  border: Border.all(
                    color: color.withValues(alpha: i <= collected ? 0.8 : 0.35),
                  ),
                ),
              ),
              if (i < total) const SizedBox(width: 4),
            ],
            const SizedBox(width: 8),
            Text(
              '$collected/$total collected',
              style: textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (!_isComplete) ...[
          const SizedBox(height: 5),
          // Progress bar — glows when ≥60% collected.
          _ProgressBar(value: collected / total, color: color, glow: _isClose),
          const SizedBox(height: 3),
          Text(
            '$_remaining more to unlock',
            style: textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: _isClose ? 0.90 : 0.65),
              fontWeight: _isClose ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.color,
    required this.glow,
  });

  final double value; // 0.0 – 1.0
  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: glow
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.65),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
