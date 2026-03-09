import 'package:flutter/material.dart';

class AppScale {
  AppScale._();

  static const double baseWidth = 390;
  static const double maxContentWidth = 720;

  static double _screenWidth = baseWidth;
  static double _screenHeight = 844;
  static double _scale = 1;
  static double _textScaleFactor = 1;
  static EdgeInsets _viewInsets = EdgeInsets.zero;
  static EdgeInsets _padding = EdgeInsets.zero;

  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _scale = _screenWidth / baseWidth;
    _textScaleFactor = mediaQuery.textScaler.scale(1);
    _viewInsets = mediaQuery.viewInsets;
    _padding = mediaQuery.padding;
  }

  static double get scale => _scale;
  static double get textScaleFactor => _textScaleFactor;
  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
  static bool get isLandscape => _screenWidth > _screenHeight;
  static EdgeInsets get viewInsets => _viewInsets;
  static EdgeInsets get padding => _padding;

  static double s(double value) => value * _scale;

  static double radius(double value) => value * _scale;

  static double icon(double value, {double? min, double? max}) {
    final scaled = value * _scale;
    return _clamp(scaled, min: min ?? value * 0.9, max: max ?? value * 1.6);
  }

  static double font(double value, {required double min, required double max}) {
    final scaled = value * _scale * _textScaleFactor;
    return _clamp(scaled, min: min, max: max);
  }

  static TextTheme scaleTextTheme(TextTheme textTheme) {
    return textTheme.copyWith(
      headlineLarge: _scaleStyle(textTheme.headlineLarge, 32, 28, 44),
      headlineMedium: _scaleStyle(textTheme.headlineMedium, 28, 24, 40),
      headlineSmall: _scaleStyle(textTheme.headlineSmall, 24, 22, 36),
      titleLarge: _scaleStyle(textTheme.titleLarge, 24, 22, 36),
      titleMedium: _scaleStyle(textTheme.titleMedium, 16, 15, 24),
      titleSmall: _scaleStyle(textTheme.titleSmall, 14, 13, 20),
      bodyLarge: _scaleStyle(textTheme.bodyLarge, 16, 14, 22),
      bodyMedium: _scaleStyle(textTheme.bodyMedium, 14, 13, 20),
      bodySmall: _scaleStyle(textTheme.bodySmall, 12, 11, 16),
      labelLarge: _scaleStyle(textTheme.labelLarge, 14, 12, 18),
      labelMedium: _scaleStyle(textTheme.labelMedium, 12, 11, 16),
      labelSmall: _scaleStyle(textTheme.labelSmall, 11, 10, 14),
    );
  }

  static BoxConstraints centeredContentConstraints({double? maxWidth}) {
    return BoxConstraints(maxWidth: maxWidth ?? maxContentWidth);
  }

  static TextStyle? _scaleStyle(
    TextStyle? style,
    double baseSize,
    double min,
    double max,
  ) {
    if (style == null) return null;
    return style.copyWith(fontSize: font(baseSize, min: min, max: max));
  }

  static double _clamp(double value, {required double min, required double max}) {
    return value.clamp(min, max).toDouble();
  }
}
