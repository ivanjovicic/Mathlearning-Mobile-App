import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';

DialogThemeData buildDialogTheme(
  ColorScheme cs,
  ThemeShapeProfile profile,
  TextTheme textTheme,
) {
  return DialogThemeData(
    backgroundColor: cs.surfaceContainer,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.all(profile)),
    titleTextStyle: textTheme.titleLarge?.copyWith(color: cs.onSurface),
    contentTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
  );
}
