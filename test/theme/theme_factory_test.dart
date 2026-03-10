import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mathlearning/theme/themes/astra_theme.dart';
import 'package:mathlearning/theme/themes/scifi_theme.dart';
import 'package:mathlearning/theme/themes/fantasy_theme.dart';
import 'package:mathlearning/theme/themes/pastel_theme.dart';
import 'package:mathlearning/theme/themes/minimal_theme.dart';
import 'package:mathlearning/theme/themes/retro_theme.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Theme factory produces valid ThemeData', () {
    final themes = <String, ThemeData Function()>{
      'SciFi dark': SciFiTheme.dark,
      'SciFi light': SciFiTheme.light,
      'Fantasy dark': FantasyTheme.dark,
      'Fantasy light': FantasyTheme.light,
      'Pastel dark': PastelTheme.dark,
      'Pastel light': PastelTheme.light,
      'Minimal dark': MinimalTheme.dark,
      'Minimal light': MinimalTheme.light,
      'Retro dark': RetroTheme.dark,
      'Retro light': RetroTheme.light,
      'Astra dark': AstraTheme.dark,
      'Astra light': AstraTheme.light,
    };

    for (final entry in themes.entries) {
      testWidgets('${entry.key} has valid colorScheme and textTheme',
          (tester) async {
        final theme = entry.value();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const SizedBox()));
        expect(theme.colorScheme, isNotNull);
        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.textTheme.titleLarge, isNotNull);
        expect(theme.textTheme.displayLarge, isNotNull);
        expect(theme.textTheme.labelLarge, isNotNull);
        expect(theme.useMaterial3, isTrue);
      });

      testWidgets('${entry.key} has component themes', (tester) async {
        final theme = entry.value();
        await tester.pumpWidget(MaterialApp(theme: theme, home: const SizedBox()));
        expect(theme.elevatedButtonTheme.style, isNotNull);
        expect(theme.outlinedButtonTheme.style, isNotNull);
        expect(theme.inputDecorationTheme.border, isNotNull);
        expect(theme.appBarTheme.backgroundColor, isNotNull);
        expect(theme.cardTheme.shape, isNotNull);
      });
    }
  });

  group('Theme context extensions', () {
    testWidgets('provide tokens via BuildContext', (tester) async {
      late AppSpacingTokens spacing;
      late AppRadiusTokens radius;
      late AppMotionTokens motion;
      late AppElevationTokens elevation;

      await tester.pumpWidget(
        MaterialApp(
          theme: SciFiTheme.dark(),
          home: Builder(builder: (context) {
            spacing = context.spacing;
            radius = context.radius;
            motion = context.motion;
            elevation = context.elevation;
            return const SizedBox();
          }),
        ),
      );

      expect(spacing.m, isPositive);
      expect(radius.card, isPositive);
      expect(motion.normal.inMilliseconds, greaterThan(0));
      expect(elevation.level3, greaterThan(0));
    });

    testWidgets('reduceMotion reflects MediaQuery', (tester) async {
      late bool reduceMotion;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(builder: (context) {
              reduceMotion = context.reduceMotion;
              return const SizedBox();
            }),
          ),
        ),
      );

      expect(reduceMotion, isTrue);
    });
  });
}
