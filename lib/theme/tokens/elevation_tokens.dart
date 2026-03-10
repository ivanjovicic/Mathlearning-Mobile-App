/// Material 3-aligned elevation scale.
///
/// Each level maps to a specific `dp` elevation value.
/// Components reference these instead of hardcoding elevation doubles.
class AppElevation {
  const AppElevation._();

  /// Level 0: flat on surface (cards in-line, chips)
  static const double level0 = 0;

  /// Level 1: slight raise (cards, filled text fields)
  static const double level1 = 1;

  /// Level 2: moderate raise (navigation bar, bottom sheet at rest)
  static const double level2 = 3;

  /// Level 3: elevated (FAB, modal bottom sheet, menus)
  static const double level3 = 6;

  /// Level 4: high (navigation drawer, dialog)
  static const double level4 = 8;

  /// Level 5: maximum (full-screen dialog, overlay)
  static const double level5 = 12;
}
