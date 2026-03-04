import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';

AppBarTheme buildAppBarTheme(
  ColorScheme cs,
  TextTheme textTheme,
  ThemeShapeProfile profile,
) {
  return AppBarTheme(
    backgroundColor: cs.surface,
    foregroundColor: cs.onSurface,
    elevation: 0,
    scrolledUnderElevation: 2,
    titleTextStyle: textTheme.titleLarge?.copyWith(color: cs.onSurface),
    iconTheme: IconThemeData(color: cs.onSurface),
  );
}

NavigationBarThemeData buildNavigationBarTheme(ColorScheme cs) {
  return NavigationBarThemeData(
    backgroundColor: cs.surfaceContainer,
    indicatorColor: cs.primaryContainer,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: cs.onPrimaryContainer);
      }
      return IconThemeData(color: cs.onSurfaceVariant);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return TextStyle(
        color: selected ? cs.onSurface : cs.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      );
    }),
  );
}

BottomSheetThemeData buildBottomSheetTheme(
  ColorScheme cs,
  ThemeShapeProfile profile,
) {
  final r = AppRadius.verticalTop(profile);
  return BottomSheetThemeData(
    backgroundColor: cs.surfaceContainer,
    shape: RoundedRectangleBorder(borderRadius: r),
    elevation: 4,
  );
}

SnackBarThemeData buildSnackBarTheme(
  ColorScheme cs,
  ThemeShapeProfile profile,
) {
  return SnackBarThemeData(
    backgroundColor: cs.inverseSurface,
    contentTextStyle: TextStyle(color: cs.onInverseSurface),
    actionTextColor: cs.inversePrimary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.all(profile)),
  );
}
