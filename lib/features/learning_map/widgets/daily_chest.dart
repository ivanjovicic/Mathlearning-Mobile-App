import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/state/daily_run_provider.dart';

class DailyChest extends StatelessWidget {
  const DailyChest({
    super.key,
    required this.state,
    required this.onTap,
    this.size = 58,
    this.pulseOnce = false,
  });

  final DailyChestState state;
  final VoidCallback? onTap;
  final double size;
  final bool pulseOnce;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final icon = switch (state) {
      DailyChestState.locked => Icons.lock_rounded,
      DailyChestState.ready => Icons.card_giftcard_rounded,
      DailyChestState.opened => Icons.inventory_2_rounded,
    };

    final background = switch (state) {
      DailyChestState.locked => colors.surfaceContainerLow,
      DailyChestState.ready => colors.tertiaryContainer,
      DailyChestState.opened => colors.primaryContainer,
    };

    final border = switch (state) {
      DailyChestState.locked => colors.outlineVariant,
      DailyChestState.ready => colors.tertiary,
      DailyChestState.opened => colors.primary,
    };

    Widget chest = GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!.call();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: border, width: size >= 90 ? 3 : 2),
          boxShadow: state == DailyChestState.ready
              ? [
                  BoxShadow(
                    color: border.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1.5,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: border, size: size * 0.46),
      ),
    );

    if (state == DailyChestState.ready && pulseOnce) {
      return chest
          .animate()
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.08, 1.08),
            duration: 260.ms,
            curve: Curves.easeOutBack,
          )
          .then()
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1, 1),
            duration: 180.ms,
            curve: Curves.easeOut,
          );
    }

    if (state == DailyChestState.ready) {
      chest = chest
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1.04, 1.04),
            duration: 900.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .shimmer(duration: 1500.ms, color: border.withValues(alpha: 0.18));
    }

    return chest;
  }
}
