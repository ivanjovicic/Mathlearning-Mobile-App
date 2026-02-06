import 'package:flutter/material.dart';

class StreakFlame extends StatelessWidget {
  final int streak;

  const StreakFlame({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.45),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 40,
            ),
            const SizedBox(width: 6),
            Text(
              "$streak",
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
