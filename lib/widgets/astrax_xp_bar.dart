import 'package:flutter/material.dart';

class AstraXPBar extends StatelessWidget {
  final double progress;
  final String? label;

  const AstraXPBar({
    super.key,
    required this.progress,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(24),
          ),
          child: FractionallySizedBox(
            widthFactor: clamped,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.tertiary,
                    cs.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
