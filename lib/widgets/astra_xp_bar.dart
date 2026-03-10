import 'package:flutter/material.dart';

class AstraXPBar extends StatelessWidget {
  final double progress;

  const AstraXPBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final normalized = progress.clamp(0.0, 1.0);
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(24),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: normalized,
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
                color: cs.primary.withValues(alpha: 0.4),
                blurRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
