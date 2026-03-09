import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_shadows.dart';
import 'tokens/app_typography.dart';

class AppThemeLight {
  const AppThemeLight._();

  static ThemeData build({bool highContrast = false}) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF0B5FFF),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDCE8FF),
      onPrimaryContainer: const Color(0xFF001C4F),
      secondary: const Color(0xFF7D3AF2),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFE9DDFF),
      onSecondaryContainer: const Color(0xFF2B0A67),
      tertiary: const Color(0xFF0B8F78),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFD0F6EE),
      onTertiaryContainer: const Color(0xFF002C24),
      error: AppBaseColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: const Color(0xFFF7F9FC),
      onSurface: const Color(0xFF111827),
      surfaceContainerHighest: Colors.white,
      onSurfaceVariant: const Color(0xFF4B5563),
      outline: const Color(0xFFD2D9E5),
      outlineVariant: const Color(0xFFE5EAF3),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFF111827),
      onInverseSurface: Colors.white,
      inversePrimary: const Color(0xFF9CC2FF),
      surfaceTint: const Color(0xFF0B5FFF),
    );

    final textTheme = AppTypography.scaleTheme(
      GoogleFonts.interTextTheme(
        Typography.material2021(platform: TargetPlatform.android).black,
      ),
      colorScheme,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      cardColor: colorScheme.surfaceContainerHighest,
      dividerColor: colorScheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerHighest,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor:
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
      ),
    );

    return base.copyWith(
      extensions: [
        const AppShadowTheme(),
      ],
    );
  }
}
