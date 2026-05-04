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
  });

  final String fragmentName;
  final int collected;
  final int total;
  final FragmentRarity rarity;
  final IconData icon;
  final bool animate;
  final String heading;
  final VoidCallback? onViewCollection;

  bool get _isCompleted => collected >= total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rarityColor = rarity.color(colors);

    Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          Row(
            children: [
              // Fragment icon with spin
              _FragmentIcon(
                color: rarityColor,
                icon: icon,
                animate: animate,
                isCompleted: _isCompleted,
              ),
              const SizedBox(width: 12),
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
          // "View collection" / "Equip later" CTA row — only shown when item
          // is fully unlocked and the caller provides an onViewCollection callback.
          if (_isCompleted && onViewCollection != null) ...
            [
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
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

class _FragmentIcon extends StatelessWidget {
  const _FragmentIcon({
    required this.color,
    required this.icon,
    required this.animate,
    this.isCompleted = false,
  });

  final Color color;
  final IconData icon;
  final bool animate;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    Widget w = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );

    // When the item is fully unlocked, overlay a check badge.
    if (isCompleted) {
      w = Stack(
        clipBehavior: Clip.none,
        children: [
          w,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (animate) {
      w = w
          .animate()
          .rotate(
            begin: -0.25,
            end: 0,
            duration: 420.ms,
            curve: Curves.easeOutBack,
          )
          .scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1.0, 1.0),
            duration: 380.ms,
            curve: Curves.easeOutBack,
          );
    }

    return w;
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          const SizedBox(height: 3),
          Text(
            '$_remaining more to unlock',
            style: textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Collect $total to unlock this item',
            style: textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.45),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}
