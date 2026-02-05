import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_sci_fi.dart';
import '../widgets/game_theme_transition.dart';
import 'theme_fantasy.dart';
import 'theme_pastel.dart';
import 'theme_minimal.dart';
import 'theme_retro.dart';

enum AppThemeType { sciFi, fantasy, pastel, minimal, retro }

class ThemeController extends ChangeNotifier {
  AppThemeType _currentType = AppThemeType.sciFi;
  bool _reduceMotion = false;
  bool _highContrast = false;
  bool _useGamifiedHome = true;
  bool isSwitching = false;

  AppThemeType get currentType => _currentType;
  bool get reduceMotion => _reduceMotion;
  bool get highContrast => _highContrast;
  bool get useGamifiedHome => _useGamifiedHome;

  ThemeData get currentTheme {
    final baseTheme = _mapTheme(_currentType);
    return _highContrast ? _applyHighContrast(baseTheme) : baseTheme;
  }

  ThemeController() {
    _loadSavedTheme();
  }

  void setTheme(AppThemeType type, [BuildContext? context]) {
    if (_currentType == type) return;

    final oldTheme = currentTheme;
    isSwitching = !_reduceMotion;
    _currentType = type;
    notifyListeners();

    // persist choice (fire-and-forget)
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('app_theme', type.index);
    });

    // trigger visual animator if available in the widget tree
    if (context != null) {
      if (!_reduceMotion) {
        try {
          final anim = context
              .findAncestorStateOfType<GameThemeTransitionState>();
          anim?.play(
            oldTheme.colorScheme.primary,
            currentTheme.colorScheme.primary,
          );
        } catch (_) {
          // ignore if animator not present
        }
      }
    }

    // Clear switching flag after transition duration so widgets can react
    if (!_reduceMotion) {
      Future.delayed(const Duration(milliseconds: 900), () {
        isSwitching = false;
        notifyListeners();
      });
    }
  }

  void setReduceMotion(bool enabled) {
    if (_reduceMotion == enabled) return;
    _reduceMotion = enabled;
    isSwitching = false;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('reduce_motion', enabled);
    });
  }

  void setHighContrast(bool enabled) {
    if (_highContrast == enabled) return;
    _highContrast = enabled;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('high_contrast', enabled);
    });
  }

  void setUseGamifiedHome(bool enabled) {
    if (_useGamifiedHome == enabled) return;
    _useGamifiedHome = enabled;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('use_gamified_home', enabled);
    });
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt('app_theme');
      _reduceMotion = prefs.getBool('reduce_motion') ?? false;
      _highContrast = prefs.getBool('high_contrast') ?? false;
      _useGamifiedHome = prefs.getBool('use_gamified_home') ?? true;
      if (index != null && index >= 0 && index < AppThemeType.values.length) {
        _currentType = AppThemeType.values[index];
      }
      notifyListeners();
    } catch (_) {
      // ignore and keep default
    }
  }

  ThemeData _mapTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.fantasy:
        return FantasyTheme.data;
      case AppThemeType.pastel:
        return PastelTheme.data;
      case AppThemeType.minimal:
        return MinimalTheme.data;
      case AppThemeType.retro:
        return RetroTheme.data;
      default:
        return SciFiTheme.data;
    }
  }

  ThemeData _applyHighContrast(ThemeData base) {
    final scheme = base.colorScheme;
    final hcScheme = scheme.copyWith(
      onPrimary: _onFor(scheme.primary),
      onSecondary: _onFor(scheme.secondary),
      onTertiary: _onFor(scheme.tertiary),
      onSurface: _onFor(scheme.surface),
      onError: _onFor(scheme.error),
      onPrimaryContainer: _onFor(scheme.primaryContainer),
      onSecondaryContainer: _onFor(scheme.secondaryContainer),
      onTertiaryContainer: _onFor(scheme.tertiaryContainer),
      onErrorContainer: _onFor(scheme.errorContainer),
      onSurfaceVariant: _onFor(scheme.surfaceContainerHighest),
      outline: _onFor(scheme.surface).withValues(alpha: 0.65),
      outlineVariant: _onFor(scheme.surface).withValues(alpha: 0.45),
    );

    final hcTextTheme = base.textTheme
        .apply(
          bodyColor: hcScheme.onSurface,
          displayColor: hcScheme.onSurface,
        )
        .copyWith(
          bodySmall: base.textTheme.bodySmall?.copyWith(
            color: hcScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: base.textTheme.labelSmall?.copyWith(
            color: hcScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        );

    return base.copyWith(
      colorScheme: hcScheme,
      textTheme: hcTextTheme,
      dividerColor: hcScheme.outline,
      disabledColor: hcScheme.onSurface.withValues(alpha: 0.55),
    );
  }

  Color _onFor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
