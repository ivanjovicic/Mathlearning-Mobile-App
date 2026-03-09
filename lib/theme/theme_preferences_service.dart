import 'package:shared_preferences/shared_preferences.dart';
import 'theme_controller.dart';

class ThemePreferencesService {
  static const _keyTheme = 'theme_type';
  static const _keyReduceMotion = 'reduce_motion';
  static const _keyHighContrast = 'high_contrast';

  Future<void> saveTheme(AppThemeType? type) async {
    if (type == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, type.name);
  }

  Future<void> saveReduceMotion(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReduceMotion, enabled);
  }

  Future<void> saveHighContrast(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrast, enabled);
  }

  // Kept for backward compatibility — useGamifiedHome removed from ThemeSettings.
  Future<void> saveGamifiedHome(bool enabled) async {}

  Future<ThemeSettings> loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final typeName = prefs.getString(_keyTheme);
    final type = AppThemeType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => AppThemeType.sciFi,
    );

    return ThemeSettings(
      type: type,
      reduceMotion: prefs.getBool(_keyReduceMotion) ?? false,
      highContrast: prefs.getBool(_keyHighContrast) ?? false,
    );
  }
}
