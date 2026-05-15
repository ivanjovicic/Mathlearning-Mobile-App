import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/cosmetic_target.dart';
import 'cosmetic_visuals.dart';

class TargetFragmentFoundBanner extends StatelessWidget {
  const TargetFragmentFoundBanner({super.key, required this.event});

  final CosmeticTargetProgressEvent event;

  @override
  Widget build(BuildContext context) {
    final color = CosmeticVisuals.rarityColor(event.target.targetRarity);
    final gained = event.fragmentsGained.clamp(1, 999);
    final helper = event.didComplete
        ? '${event.itemName} is ready to unlock.'
        : 'You are now $gained fragment closer to ${event.itemName}.';
    final heading = event.bonusFragmentEarned
        ? 'BONUS FRAGMENT EARNED!'
        : 'TARGET FRAGMENT FOUND!';

    return Container(
          key: const Key('target_fragment_found_banner'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.32),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const Key('target_fragment_confetti_burst'),
                    painter: _TargetConfettiPainter(color: color),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.gps_fixed_rounded, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heading,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          helper,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 180.ms)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.0, 1.0),
          duration: 240.ms,
          curve: Curves.easeOutBack,
        )
        .shimmer(duration: 900.ms, color: color.withValues(alpha: 0.28));
  }
}

class _BonusProgressPip extends StatelessWidget {
  const _BonusProgressPip({
    required this.index,
    required this.filled,
    required this.isFinalFilled,
    required this.color,
  });

  final int index;
  final bool filled;
  final bool isFinalFilled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final pipKey = Key(
      isFinalFilled
          ? 'bonus_progress_final_chain'
          : 'bonus_progress_pip_$index',
    );
    final beginScale = filled && !reduceMotion ? 0.58 : 1.0;

    return TweenAnimationBuilder<double>(
      key: pipKey,
      tween: Tween<double>(begin: beginScale, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : Duration(milliseconds: 220 + index * 45),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : Duration(milliseconds: 140 + index * 45),
        curve: Curves.easeOutBack,
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : color.withValues(alpha: 0.18),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isFinalFilled ? 0.72 : 0.48),
                    blurRadius: isFinalFilled ? 10 : 6,
                    spreadRadius: isFinalFilled ? 1 : 0,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _TargetConfettiPainter extends CustomPainter {
  const _TargetConfettiPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 26; i++) {
      final x = ((i * 37) % 100) / 100;
      final y = ((i * 53) % 100) / 100;
      final radius = 1.7 + (i % 4) * 0.8;
      final alpha = 0.22 + (i % 5) * 0.07;
      paint.color = (i % 4 == 0 ? Colors.white : color).withValues(
        alpha: alpha,
      );
      canvas.drawCircle(Offset(size.width * x, size.height * y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_TargetConfettiPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Thin shim kept so callers that still reference TargetEnergyProgressRow
/// compile. Delegates to [BonusProgressRow].
class TargetEnergyProgressRow extends StatelessWidget {
  const TargetEnergyProgressRow({super.key, required this.event});

  final CosmeticTargetProgressEvent event;

  @override
  Widget build(BuildContext context) => BonusProgressRow(event: event);
}

/// Visible bonus-fragment progress shown in the reward sheet after every
/// non-target run.  Displays a 5-segment pip row + label.
class BonusProgressRow extends StatelessWidget {
  const BonusProgressRow({super.key, required this.event});

  final CosmeticTargetProgressEvent event;

  @override
  Widget build(BuildContext context) {
    final color = CosmeticVisuals.rarityColor(event.target.targetRarity);
    final current = event.target.bonusProgress;
    final max = CosmeticTarget.kBonusProgressMax;
    final awarded = event.bonusProgressAwarded;

    return Container(
      key: const Key('bonus_progress_row'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  awarded > 0
                      ? '+$awarded Bonus Fragment Progress · toward ${event.itemName}'
                      : 'Bonus Fragment Progress · toward ${event.itemName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(max, (i) {
                      final filled = i < current;
                      return _BonusProgressPip(
                        index: i,
                        filled: filled,
                        isFinalFilled: current >= max && i == max - 1,
                        color: color,
                      );
                    }),
                    const SizedBox(width: 4),
                    Text(
                      '$current/$max',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.80),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.10);
  }
}
