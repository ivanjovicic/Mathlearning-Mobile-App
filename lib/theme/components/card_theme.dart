import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';

CardThemeData buildCardTheme(ColorScheme cs, ThemeShapeProfile profile) {
  return CardThemeData(
    color: cs.surfaceContainerHigh,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.all(profile),
    ),
  );
}
