import 'package:flutter/material.dart';

class ThemeStatusFooter extends StatelessWidget {
  final bool reduceMotion;
  final bool highContrast;

  const ThemeStatusFooter({
    super.key,
    required this.reduceMotion,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      "Reduce motion: ${reduceMotion ? "ukljucen" : "iskljucen"} | "
      "High contrast: ${highContrast ? "ukljucen" : "iskljucen"}",
      style: TextStyle(color: colorScheme.onSurfaceVariant),
    );
  }
}