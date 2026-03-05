import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'theme_preferences_service.dart';
import 'astrax_theme.dart';
import '../widgets/game_theme_transition.dart';
import 'themes/fantasy_theme.dart';
import 'themes/pastel_theme.dart';
import 'themes/minimal_theme.dart';
import 'themes/retro_theme.dart';
import 'themes/scifi_theme.dart';

enum AppThemeType { sciFi, fantasy, pastel, minimal, retro, astra }

class ThemeController extends ChangeNotifier {
  final ThemePreferencesService _preferencesService;

  ThemeSettings _state;
  final Map<AppThemeType, ThemeData> _themeCache = {};
  bool isSwitching = false;
  bool _autoTuningInProgress = false;

  ThemeController([ThemePreferencesService? preferencesService])
      : _preferencesService = preferencesService ?? ThemePreferencesService(),
        _state = ThemeSettings.initial() {
    _loadSavedPreferences();
  }

  AppThemeType get currentType => _state.type;
  bool get reduceMotion => _state.reduceMotion;
  bool get highContrast => _state.highContrast;
  bool get useGamifiedHome => _state.useGamifiedHome;

  ThemeData get currentTheme {
    final baseTheme = _getCachedTheme(_state.type);
    return _state.highContrast ? _buildHighContrastTheme(baseTheme) : baseTheme;
  }

  void setTheme(AppThemeType type, [BuildContext? context]) async {
    if (_state.type == type) return;

    final oldTheme = currentTheme;
    _setSwitching(true);
    _state = _state.copyWith(type: type);
    notifyListeners();

    _triggerThemeTransition(context, oldTheme, currentTheme);
    await _preferencesService.saveTheme(type);
    _setSwitching(false);
  }

  void setReduceMotion(bool enabled) async {
    if (_state.reduceMotion == enabled) return;
    _state = _state.copyWith(reduceMotion: enabled);
    notifyListeners();
    await _preferencesService.saveReduceMotion(enabled);
  }

  void setHighContrast(bool enabled) async {
    if (_state.highContrast == enabled) return;
    _state = _state.copyWith(highContrast: enabled);
    notifyListeners();
    await _preferencesService.saveHighContrast(enabled);
  }

  void setUseGamifiedHome(bool enabled) async {
    if (_state.useGamifiedHome == enabled) return;
    _state = _state.copyWith(useGamifiedHome: enabled);
    notifyListeners();
    await _preferencesService.saveGamifiedHome(enabled);
  }

  Future<void> _loadSavedPreferences() async {
    final savedState = await _preferencesService.loadAllPreferences();
    _state = savedState;
    notifyListeners();

    if (!_state.reduceMotion) {
      _autoTuneMotionForDevice();
    }
  }

  void _autoTuneMotionForDevice() {
    if (_autoTuningInProgress) return;
    _autoTuningInProgress = true;

    const sampleFrames = 30;
    final samples = <double>[];
    late TimingsCallback callback;

    callback = (List<FrameTiming> timings) {
      for (final timing in timings) {
        samples.add(timing.totalSpan.inMicroseconds / 1000.0);
        if (samples.length >= sampleFrames) break;
      }

      if (samples.length < sampleFrames) return;

      SchedulerBinding.instance.removeTimingsCallback(callback);
      _autoTuningInProgress = false;

      const frameBudgetMs = 16.67;
      const jankThresholdMs = 20.0;
      const jankRatioThreshold = 0.35;

      final avgMs =
          samples.reduce((sum, value) => sum + value) / samples.length;
      final jankyCount = samples.where((ms) => ms > jankThresholdMs).length;
      final jankRatio = jankyCount / samples.length;

      if (avgMs > frameBudgetMs || jankRatio >= jankRatioThreshold) {
        setReduceMotion(true);
      }
    };

    SchedulerBinding.instance.addTimingsCallback(callback);
  }

  ThemeData _getCachedTheme(AppThemeType type) {
    if (!_themeCache.containsKey(type)) {
      _themeCache[type] = _mapTheme(type);
    }
    return _themeCache[type]!;
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
      case AppThemeType.astra:
        return AstraXTheme.buildDarkTheme();
      default:
        return SciFiTheme.data;
    }
  }

  ThemeData _buildHighContrastTheme(ThemeData base) {
    final scheme = base.colorScheme;
    final hcScheme = scheme.copyWith(
      onPrimary: _contrastColorFor(scheme.primary),
      onSecondary: _contrastColorFor(scheme.secondary),
      onTertiary: _contrastColorFor(scheme.tertiary),
      onSurface: _contrastColorFor(scheme.surface),
      onError: _contrastColorFor(scheme.error),
      onPrimaryContainer: _contrastColorFor(scheme.primaryContainer),
      onSecondaryContainer: _contrastColorFor(scheme.secondaryContainer),
      onTertiaryContainer: _contrastColorFor(scheme.tertiaryContainer),
      onErrorContainer: _contrastColorFor(scheme.errorContainer),
      onSurfaceVariant: _contrastColorFor(scheme.surfaceContainerHighest),
      outline: _contrastColorFor(scheme.surface).withValues(alpha: 0.65),
      outlineVariant: _contrastColorFor(scheme.surface).withValues(alpha: 0.45),
    );

    return base.copyWith(colorScheme: hcScheme);
  }

  Color _contrastColorFor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  void _triggerThemeTransition(
      BuildContext? context, ThemeData oldTheme, ThemeData newTheme) {
    if (context == null || _state.reduceMotion) return;

    final anim = context.findAncestorStateOfType<GameThemeTransitionState>();
    anim?.play(
      oldTheme.colorScheme.primary,
      newTheme.colorScheme.primary,
    );
  }

  void _setSwitching(bool value) {
    if (isSwitching == value) return;
    isSwitching = value;
    notifyListeners();
  }
}

class ThemeSettings {
  final AppThemeType type;
  final bool reduceMotion;
  final bool highContrast;
  final bool useGamifiedHome;

  ThemeSettings({
    required this.type,
    required this.reduceMotion,
    required this.highContrast,
    required this.useGamifiedHome,
  });

  factory ThemeSettings.initial() {
    return ThemeSettings(
      type: AppThemeType.sciFi,
      reduceMotion: false,
      highContrast: false,
      useGamifiedHome: true,
    );
  }

  ThemeSettings copyWith({
    AppThemeType? type,
    bool? reduceMotion,
    bool? highContrast,
    bool? useGamifiedHome,
  }) {
    return ThemeSettings(
      type: type ?? this.type,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      useGamifiedHome: useGamifiedHome ?? this.useGamifiedHome,
    );
  }
}
