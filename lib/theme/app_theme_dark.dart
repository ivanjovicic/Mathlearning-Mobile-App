import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_radius.dart';
import 'tokens/app_shadows.dart';
import 'tokens/app_typography.dart';

class AppThemeDark {
  const AppThemeDark._();

  static ThemeData build({bool highContrast = false}) {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppBaseColors.primary,
      onPrimary: AppBaseColors.neutral0,
      primaryContainer: const Color(0xFF163457),
      onPrimaryContainer: const Color(0xFFD7EBFF),
      secondary: AppBaseColors.secondary,
      onSecondary: AppBaseColors.neutral0,
      secondaryContainer: const Color(0xFF35244A),
      onSecondaryContainer: const Color(0xFFF2DDFF),
      tertiary: AppBaseColors.accent,
      onTertiary: AppBaseColors.neutral950,
      tertiaryContainer: const Color(0xFF144F44),
      onTertiaryContainer: const Color(0xFFC5FFF1),
      error: AppBaseColors.error,
      onError: AppBaseColors.neutral0,
      errorContainer: const Color(0xFF5A2021),
      onErrorContainer: const Color(0xFFFFDAD7),
      surface: const Color(0xFF0D1320),
      onSurface: const Color(0xFFF1F5F9),
      surfaceContainerHighest: const Color(0xFF1A2437),
      onSurfaceVariant: const Color(0xFFA9B7CE),
      outline: const Color(0xFF3E4B64),
      outlineVariant: const Color(0xFF2A354A),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFE2E8F0),
      onInverseSurface: const Color(0xFF0D1320),
      inversePrimary: const Color(0xFF8EC5FF),
      surfaceTint: AppBaseColors.primary,
    );

    final textTheme = AppTypography.scaleTheme(
      GoogleFonts.interTextTheme(
        Typography.material2021(platform: TargetPlatform.android).white,
      ),
      colorScheme,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
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
