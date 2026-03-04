import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography builder — each theme supplies a [TypographyConfig] to specify
/// its unique font family (and any overrides), then calls [buildTextTheme].
class TypographyConfig {
  final TextStyle Function(TextStyle base) displayBuilder;
  final TextStyle Function(TextStyle base) headlineBuilder;
  final TextStyle Function(TextStyle base) bodyBuilder;
  final TextStyle Function(TextStyle base) labelBuilder;

  const TypographyConfig({
    required this.displayBuilder,
    required this.headlineBuilder,
    required this.bodyBuilder,
    required this.labelBuilder,
  });

  /// Pastel / Minimal — Quicksand for everything.
  static final quicksand = TypographyConfig(
    displayBuilder: (b) => GoogleFonts.quicksand(
      textStyle: b.copyWith(fontWeight: FontWeight.w700),
    ),
    headlineBuilder: (b) => GoogleFonts.quicksand(
      textStyle: b.copyWith(fontWeight: FontWeight.w600),
    ),
    bodyBuilder: (b) => GoogleFonts.quicksand(textStyle: b),
    labelBuilder: (b) => GoogleFonts.quicksand(
      textStyle: b.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  /// Fantasy — Marcellus for display/headline, Lora for body.
  static final fantasy = TypographyConfig(
    displayBuilder: (b) => GoogleFonts.marcellus(
      textStyle: b.copyWith(fontWeight: FontWeight.w700),
    ),
    headlineBuilder: (b) => GoogleFonts.marcellus(
      textStyle: b.copyWith(fontWeight: FontWeight.w600),
    ),
    bodyBuilder: (b) => GoogleFonts.lora(textStyle: b),
    labelBuilder: (b) => GoogleFonts.lora(
      textStyle: b.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  /// SciFi — Orbitron for display/headline, Inter for body, Rajdhani for labels.
  static final sciFi = TypographyConfig(
    displayBuilder: (b) => GoogleFonts.orbitron(
      textStyle: b.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.5),
    ),
    headlineBuilder: (b) => GoogleFonts.orbitron(
      textStyle: b.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
    ),
    bodyBuilder: (b) => GoogleFonts.inter(textStyle: b),
    labelBuilder: (b) => GoogleFonts.rajdhani(
      textStyle: b.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.1),
    ),
  );

  /// Retro — PressStart2P for display/headline/labels, ShareTechMono for body.
  static final retro = TypographyConfig(
    displayBuilder: (b) => GoogleFonts.pressStart2p(textStyle: b),
    headlineBuilder: (b) => GoogleFonts.pressStart2p(textStyle: b),
    bodyBuilder: (b) => GoogleFonts.shareTechMono(textStyle: b),
    labelBuilder: (b) => GoogleFonts.pressStart2p(textStyle: b),
  );
}

/// Builds the full Material 3 [TextTheme] from a [TypographyConfig] and
/// a base [ColorScheme].  All text slots are populated so that widgets
/// that reference any TextTheme slot always get a styled TextStyle.
TextTheme buildTextTheme(TypographyConfig cfg, ColorScheme cs) {
  TextStyle on = TextStyle(color: cs.onSurface);
  TextStyle onV = TextStyle(color: cs.onSurfaceVariant);

  return TextTheme(
    displayLarge: cfg.displayBuilder(on.copyWith(fontSize: 57)),
    displayMedium: cfg.displayBuilder(on.copyWith(fontSize: 45)),
    displaySmall: cfg.displayBuilder(on.copyWith(fontSize: 36)),
    headlineLarge: cfg.headlineBuilder(on.copyWith(fontSize: 32)),
    headlineMedium: cfg.headlineBuilder(on.copyWith(fontSize: 28)),
    headlineSmall: cfg.headlineBuilder(on.copyWith(fontSize: 24)),
    titleLarge: cfg.headlineBuilder(on.copyWith(fontSize: 22)),
    titleMedium: cfg.headlineBuilder(
        on.copyWith(fontSize: 16, fontWeight: FontWeight.w500)),
    titleSmall: cfg.headlineBuilder(
        on.copyWith(fontSize: 14, fontWeight: FontWeight.w500)),
    bodyLarge: cfg.bodyBuilder(on.copyWith(fontSize: 16)),
    bodyMedium: cfg.bodyBuilder(onV.copyWith(fontSize: 14)),
    bodySmall: cfg.bodyBuilder(onV.copyWith(fontSize: 12)),
    labelLarge: cfg.labelBuilder(on.copyWith(fontSize: 14)),
    labelMedium: cfg.labelBuilder(onV.copyWith(fontSize: 12)),
    labelSmall: cfg.labelBuilder(onV.copyWith(fontSize: 11)),
  );
}
