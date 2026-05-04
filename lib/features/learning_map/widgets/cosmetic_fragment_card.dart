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
/// collection progress ("2/5 fragments").
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
  });

  final String fragmentName;
  final int collected;
  final int total;
  final FragmentRarity rarity;
  final IconData icon;
  final bool animate;
  final String heading;

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
        ],
      ),
      child: Row(
        children: [
          // Fragment icon with spin
          _FragmentIcon(color: rarityColor, icon: icon, animate: animate),
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
              rarity.label,
              style: textTheme.labelSmall?.copyWith(
                color: rarityColor,
                fontWeight: FontWeight.w900,
              ),
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
    }

    return card;
  }
}

class _FragmentIcon extends StatelessWidget {
  const _FragmentIcon({
    required this.color,
    required this.icon,
    required this.animate,
  });

  final Color color;
  final IconData icon;
  final bool animate;

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

  @override
  Widget build(BuildContext context) {
    return Row(
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
          '$collected/$total fragments',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
