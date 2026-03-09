import 'package:flutter/material.dart';

import '../theme/theme_extensions/theme_context.dart';
import '../ui/components/app_card.dart';

class AccessibilitySettingsSection extends StatelessWidget {
  const AccessibilitySettingsSection({
    super.key,
    required this.reduceMotion,
    required this.highContrast,
    required this.onReduceMotionChanged,
    required this.onHighContrastChanged,
  });

  final bool reduceMotion;
  final bool highContrast;
  final ValueChanged<bool> onReduceMotionChanged;
  final ValueChanged<bool> onHighContrastChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          margin: EdgeInsets.only(bottom: spacing.s),
          child: SwitchListTile(
            value: reduceMotion,
            onChanged: onReduceMotionChanged,
            title: const Text('Reduce motion'),
            subtitle: const Text('Smanjuje animacije i tranzicije'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        AppCard(
          child: SwitchListTile(
            value: highContrast,
            onChanged: onHighContrastChanged,
            title: const Text('High contrast'),
            subtitle: const Text('Pojacava citljivost teksta i UI elemenata'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
