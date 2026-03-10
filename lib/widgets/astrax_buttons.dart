import 'dart:ui';
import 'package:flutter/material.dart';

class AstraGlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const AstraGlassButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.primary.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AstraNeonButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const AstraNeonButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 26),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.secondary.withValues(alpha: 0.95),
              cs.primary.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: cs.secondary.withValues(alpha: 0.5),
              blurRadius: 26,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class AstraSoftButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  const AstraSoftButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.85),
              offset: const Offset(4, 4),
              blurRadius: 14,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.07),
              offset: const Offset(-3, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
