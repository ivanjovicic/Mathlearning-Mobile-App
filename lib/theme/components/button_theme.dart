import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';

ElevatedButtonThemeData buildElevatedButtonTheme(
  ColorScheme cs,
  ThemeShapeProfile profile,
) {
  final r = AppRadius.all(profile);
  return ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return cs.onSurface.withValues(alpha: 0.12);
        }
        return cs.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return cs.onSurface.withValues(alpha: 0.38);
        }
        return cs.onPrimary;
      }),
      elevation: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.pressed) ? 1 : 3),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: r),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      ),
    ),
  );
}

OutlinedButtonThemeData buildOutlinedButtonTheme(
  ColorScheme cs,
  ThemeShapeProfile profile,
) {
  final r = AppRadius.all(profile);
  return OutlinedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(cs.primary),
      side: WidgetStateProperty.all(
        BorderSide(color: cs.primary.withValues(alpha: 0.6), width: 1.5),
      ),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: r)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      ),
    ),
  );
}

TextButtonThemeData buildTextButtonTheme(
  ColorScheme cs,
  ThemeShapeProfile profile,
) {
  final r = AppRadius.all(profile);
  return TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(cs.primary),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: r)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
  );
}
