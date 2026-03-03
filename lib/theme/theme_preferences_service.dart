import 'theme_controller.dart';

class ThemePreferencesService {
  // Minimal shim implementing the methods used by ThemeController.
  Future<void> saveTheme(AppThemeType? type) async {
    // no-op shim
    return;
  }

  Future<void> saveReduceMotion(bool enabled) async {
    return;
  }

  Future<void> saveHighContrast(bool enabled) async {
    return;
  }

  Future<void> saveGamifiedHome(bool enabled) async {
    return;
  }

  Future<ThemeSettings> loadAllPreferences() async {
    // Return defaults matching ThemeSettings.initial()
    return ThemeSettings.initial();
  }
}
