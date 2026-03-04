import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';

InputDecorationTheme buildInputTheme(
  ColorScheme cs,
  ThemeShapeProfile profile,
) {
  final r = AppRadius.all(profile);
  final border = OutlineInputBorder(
    borderRadius: r,
    borderSide: BorderSide(color: cs.outlineVariant),
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: cs.surfaceContainerHighest,
    labelStyle: TextStyle(color: cs.onSurfaceVariant),
    hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: r,
      borderSide: BorderSide(color: cs.primary, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: r,
      borderSide: BorderSide(color: cs.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: r,
      borderSide: BorderSide(color: cs.error, width: 2),
    ),
  );
}
