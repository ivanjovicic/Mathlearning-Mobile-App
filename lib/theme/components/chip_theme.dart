import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';

ChipThemeData buildChipTheme(ColorScheme cs, ThemeShapeProfile profile) {
  return ChipThemeData(
    backgroundColor: cs.surfaceContainerHigh,
    selectedColor: cs.primaryContainer,
    labelStyle: TextStyle(color: cs.onSurface),
    secondaryLabelStyle: TextStyle(color: cs.onPrimaryContainer),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.all(profile)),
    side: BorderSide(color: cs.outlineVariant),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}

DividerThemeData buildDividerTheme(ColorScheme cs) {
  return DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1);
}

SwitchThemeData buildSwitchTheme(ColorScheme cs) {
  return SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return cs.onPrimary;
      return cs.outline;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return cs.primary;
      return cs.surfaceContainerHighest;
    }),
  );
}

TooltipThemeData buildTooltipTheme(ColorScheme cs, ThemeShapeProfile profile) {
  return TooltipThemeData(
    decoration: BoxDecoration(
      color: cs.inverseSurface,
      borderRadius: AppRadius.all(profile),
    ),
    textStyle: TextStyle(color: cs.onInverseSurface, fontSize: 12),
  );
}
