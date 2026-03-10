import 'package:flutter/material.dart';

class AstraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AstraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
            currentIndex: currentIndex,
            onChanged: onChanged,
          ),
          _NavItem(
            index: 1,
            icon: Icons.bolt_rounded,
            label: 'Quiz',
            currentIndex: currentIndex,
            onChanged: onChanged,
          ),
          _NavItem(
            index: 2,
            icon: Icons.school_rounded,
            label: 'Review',
            currentIndex: currentIndex,
            onChanged: onChanged,
          ),
          _NavItem(
            index: 3,
            icon: Icons.person_rounded,
            label: 'Profile',
            currentIndex: currentIndex,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onChanged;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white10 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? cs.primary : Colors.white54,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
