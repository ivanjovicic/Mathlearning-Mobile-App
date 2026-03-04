import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../components/button_theme.dart';
import '../components/card_theme.dart';
import '../components/chip_theme.dart';
import '../components/dialog_theme.dart';
import '../components/input_theme.dart';
import '../components/navigation_theme.dart';

/// Central theme factory.
///
/// Each concrete theme calls [buildTheme] with its own [ColorScheme],
/// [TypographyConfig] and [ThemeShapeProfile].  All component builders live
/// in `components/` and are wired together here — no component logic lives
/// inside individual theme files.
ThemeData buildTheme({
  required ColorScheme colorScheme,
  required TypographyConfig typographyConfig,
  required ThemeShapeProfile shapeProfile,
}) {
  final cs = colorScheme;
  final textTheme = buildTextTheme(typographyConfig, cs);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: textTheme,

    // --- Components -------------------------------------------------------
    elevatedButtonTheme: buildElevatedButtonTheme(cs, shapeProfile),
    outlinedButtonTheme: buildOutlinedButtonTheme(cs, shapeProfile),
    textButtonTheme: buildTextButtonTheme(cs, shapeProfile),
    cardTheme: buildCardTheme(cs, shapeProfile),
    inputDecorationTheme: buildInputTheme(cs, shapeProfile),
    dialogTheme: buildDialogTheme(cs, shapeProfile, textTheme),
    appBarTheme: buildAppBarTheme(cs, textTheme, shapeProfile),
    navigationBarTheme: buildNavigationBarTheme(cs),
    bottomSheetTheme: buildBottomSheetTheme(cs, shapeProfile),
    snackBarTheme: buildSnackBarTheme(cs, shapeProfile),
    chipTheme: buildChipTheme(cs, shapeProfile),
    dividerTheme: buildDividerTheme(cs),
    switchTheme: buildSwitchTheme(cs),
    tooltipTheme: buildTooltipTheme(cs, shapeProfile),

    // --- Scaffold / surfaces ----------------------------------------------
    scaffoldBackgroundColor: cs.surface,
    canvasColor: cs.surface,
  );
}
