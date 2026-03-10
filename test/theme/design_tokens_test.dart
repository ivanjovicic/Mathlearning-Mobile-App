import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/theme/tokens/breakpoint_tokens.dart';
import 'package:mathlearning/theme/tokens/elevation_tokens.dart';
import 'package:mathlearning/theme/tokens/app_motion.dart';

void main() {
  group('AppBreakpoints', () {
    testWidgets('compact for narrow screen', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late WindowSize captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            captured = AppBreakpoints.of(context);
            return const SizedBox();
          }),
        ),
      );

      expect(captured, WindowSize.compact);
    });

    testWidgets('medium for tablet-width screen', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late WindowSize captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            captured = AppBreakpoints.of(context);
            return const SizedBox();
          }),
        ),
      );

      expect(captured, WindowSize.medium);
    });

    testWidgets('expanded for wide tablet', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late WindowSize captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            captured = AppBreakpoints.of(context);
            return const SizedBox();
          }),
        ),
      );

      expect(captured, WindowSize.expanded);
    });

    testWidgets('large for desktop-width screen', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late WindowSize captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            captured = AppBreakpoints.of(context);
            return const SizedBox();
          }),
        ),
      );

      expect(captured, WindowSize.large);
    });

    testWidgets('responsive picks correct value', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late int columns;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            columns = AppBreakpoints.responsive(
              context,
              compact: 4,
              medium: 8,
              expanded: 12,
            );
            return const SizedBox();
          }),
        ),
      );

      expect(columns, 8);
    });
  });

  group('AppElevation', () {
    test('levels are in ascending order', () {
      expect(AppElevation.level0, lessThan(AppElevation.level1));
      expect(AppElevation.level1, lessThan(AppElevation.level2));
      expect(AppElevation.level2, lessThan(AppElevation.level3));
      expect(AppElevation.level3, lessThan(AppElevation.level4));
      expect(AppElevation.level4, lessThan(AppElevation.level5));
    });
  });

  group('AppMotion', () {
    test('durations are in ascending order', () {
      expect(AppMotion.instant.inMilliseconds,
          lessThan(AppMotion.fast.inMilliseconds));
      expect(AppMotion.fast.inMilliseconds,
          lessThan(AppMotion.normal.inMilliseconds));
      expect(AppMotion.normal.inMilliseconds,
          lessThan(AppMotion.slow.inMilliseconds));
      expect(AppMotion.slow.inMilliseconds,
          lessThan(AppMotion.xSlow.inMilliseconds));
    });

    testWidgets('resolve returns Duration.zero when reduced motion',
        (tester) async {
      late Duration resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(builder: (context) {
              resolved = AppMotion.resolve(context, AppMotion.normal);
              return const SizedBox();
            }),
          ),
        ),
      );

      expect(resolved, Duration.zero);
    });

    testWidgets('resolve returns desired when motion allowed', (tester) async {
      late Duration resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: false),
            child: Builder(builder: (context) {
              resolved = AppMotion.resolve(context, AppMotion.normal);
              return const SizedBox();
            }),
          ),
        ),
      );

      expect(resolved, AppMotion.normal);
    });
  });
}
