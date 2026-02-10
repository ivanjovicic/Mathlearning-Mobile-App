import 'package:flutter/material.dart';
import '../theme/astrax_theme.dart';

class AstraXPBar extends StatelessWidget {
  final double progress;

  const AstraXPBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
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
            gradient: const LinearGradient(
              colors: [
                AstraXTheme.neonGreen,
                AstraXTheme.neonBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AstraXTheme.neonBlue.withValues(alpha: 0.4),
                blurRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
