import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Astra-quality global dark theme palette and ThemeData builder.
class MLXTheme {
  MLXTheme._();

  // ─── Core palette ───────────────────────────────────────────
  static const Color bg = Color(0xFF0B0C10);
  static const Color panel = Color(0xFF131418);
  static const Color surface = Color(0xFF1A1B21);
  static const Color surfaceHigh = Color(0xFF22232A);
  static const Color glass = Color(0x66FFFFFF); // 40 % white
  static const Color glassBorder = Color(0x33FFFFFF); // 20 % white

  // ─── Neon accents ───────────────────────────────────────────
  static const Color neonBlue = Color(0xFF4AB4FF);
  static const Color neonPurple = Color(0xFF9A5BFF);
  static const Color neonGreen = Color(0xFF4EFFB2);
  static const Color neonPink = Color(0xFFFF5CAD);
  static const Color neonGold = Color(0xFFFFD166);

  // ─── Text ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF5C6370);

  // ─── Geometry ───────────────────────────────────────────────
  static const double radius = 18;
  static const double radiusSm = 12;
  static const double radiusLg = 24;

  // ─── Gradients ──────────────────────────────────────────────
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonPurple, neonBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [neonGreen, Color(0xFF00D68F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient panelGradient = LinearGradient(
    colors: [Color(0xFF15161C), Color(0xFF1E1F27)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Full ThemeData ─────────────────────────────────────────
  static ThemeData get data {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        onPrimary: Color(0xFF001E30),
        primaryContainer: Color(0xFF1A3A50),
        onPrimaryContainer: Color(0xFFCBE6FF),
        secondary: neonPurple,
        onSecondary: Color(0xFF1B0040),
        secondaryContainer: Color(0xFF2E1A5C),
        onSecondaryContainer: Color(0xFFE1D0FF),
        tertiary: neonGreen,
        onTertiary: Color(0xFF003822),
        tertiaryContainer: Color(0xFF0A4D33),
        onTertiaryContainer: Color(0xFFB3FFD9),
        error: Color(0xFFFF6B6B),
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: Color(0xFF3A3B44),
        outlineVariant: Color(0xFF2A2B33),
        surfaceContainerHighest: surfaceHigh,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.4,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.4,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: glassBorder.withValues(alpha: 0.12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: panel,
          disabledForegroundColor: textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonBlue,
          side: BorderSide(color: neonBlue.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: glassBorder.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: glassBorder.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: neonBlue.withValues(alpha: 0.7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panel,
        selectedColor: neonBlue.withValues(alpha: 0.25),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: textPrimary),
        side: BorderSide(color: glassBorder.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panel,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: glassBorder.withValues(alpha: 0.12),
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonBlue;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neonBlue.withValues(alpha: 0.35);
          }
          return panel;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neonBlue.withValues(alpha: 0.5);
          }
          return glassBorder.withValues(alpha: 0.2);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: neonBlue,
        linearTrackColor: panel,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: glassBorder.withValues(alpha: 0.15)),
        ),
        textStyle: GoogleFonts.inter(color: textPrimary, fontSize: 12),
      ),
    );
  }
}
