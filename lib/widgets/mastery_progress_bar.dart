import 'package:flutter/material.dart';

class MasteryProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double height;
  final Duration duration;
  final bool animate;

  const MasteryProgressBar({
    super.key,
    required this.progress,
    this.height = 12,
    this.duration = const Duration(milliseconds: 500),
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        color: Colors.white24,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final targetWidth = constraints.maxWidth * clamped;
            return AnimatedContainer(
              duration: animate ? duration : Duration.zero,
              curve: Curves.easeOutCubic,
              width: targetWidth,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7CFFB2),
                    Color(0xFF2ED573),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2ED573).withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
