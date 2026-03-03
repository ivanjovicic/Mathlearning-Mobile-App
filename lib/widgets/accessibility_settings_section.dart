import 'package:flutter/material.dart';

class AccessibilitySettingsSection extends StatelessWidget {
  final bool reduceMotion;
  final bool highContrast;
  final ValueChanged<bool> onReduceMotionChanged;
  final ValueChanged<bool> onHighContrastChanged;

  const AccessibilitySettingsSection({
    super.key,
    required this.reduceMotion,
    required this.highContrast,
    required this.onReduceMotionChanged,
    required this.onHighContrastChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: reduceMotion,
          onChanged: onReduceMotionChanged,
          title: const Text("Reduce motion"),
          subtitle: const Text("Smanjuje animacije i tranzicije"),
        ),
        SwitchListTile(
          value: highContrast,
          onChanged: onHighContrastChanged,
          title: const Text("High contrast"),
          subtitle: const Text("Pojacava citljivost teksta i UI elemenata"),
        ),
      ],
    );
  }
}