import 'package:flutter/material.dart';

class ThemeOptionCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const ThemeOptionCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? colorScheme.secondary
              : colorScheme.surfaceVariant,
          width: selected ? 2.5 : 1.0,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: colorScheme.secondary.withAlpha((0.18 * 255).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          title: Text(title),
          trailing: selected
              ? Icon(
                  Icons.check_circle,
                  color: colorScheme.secondary,
                )
              : const Icon(Icons.circle_outlined),
          onTap: onTap,
        ),
      ),
    );
  }
}