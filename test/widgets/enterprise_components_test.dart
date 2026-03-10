import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/widgets/ui/astra_dialog.dart';
import 'package:mathlearning/widgets/ui/astra_loading_indicator.dart';
import 'package:mathlearning/widgets/ui/astra_section_header.dart';
import 'package:mathlearning/widgets/ui/astra_snack_bar.dart';
import 'package:mathlearning/widgets/ui/responsive_layout.dart';
import 'package:mathlearning/widgets/ui/motion_transition.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AstraDialog', () {
    testWidgets('renders title and actions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () => AstraDialog.show(
              context: context,
              title: 'Confirm',
              confirmLabel: 'Da',
              cancelLabel: 'Ne',
            ),
            child: const Text('Open'),
          );
        }),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Da'), findsOneWidget);
      expect(find.text('Ne'), findsOneWidget);
    });
  });

  group('AstraLoadingIndicator', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(_wrap(
        const AstraLoadingIndicator(label: 'Ucitavanje...'),
      ));

      expect(find.text('Ucitavanje...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders without label', (tester) async {
      await tester.pumpWidget(_wrap(
        const AstraLoadingIndicator(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AstraSectionHeader', () {
    testWidgets('renders title and trailing', (tester) async {
      await tester.pumpWidget(_wrap(
        AstraSectionHeader(
          title: 'Leaderboard',
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ),
      ));

      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('ResponsiveLayout', () {
    testWidgets('centers content with max width', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const ResponsiveLayout(child: Text('Hello')),
        ),
      ));

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(ConstrainedBox), findsWidgets);
    });
  });

  group('MotionTransition', () {
    testWidgets('fade shows child when visible', (tester) async {
      await tester.pumpWidget(_wrap(
        const MotionTransition.fade(
          visible: true,
          child: Text('Visible'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Visible'), findsOneWidget);
    });

    testWidgets('shows nothing when not visible', (tester) async {
      await tester.pumpWidget(_wrap(
        const MotionTransition.fade(
          visible: false,
          child: Text('Hidden'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hidden'), findsNothing);
    });
  });

  group('AstraSnackBar', () {
    testWidgets('shows message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => AstraSnackBar.show(context, message: 'Hello'),
              child: const Text('Show'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('error variant shows message', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () =>
                  AstraSnackBar.error(context, message: 'Network error'),
              child: const Text('Show'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Network error'), findsOneWidget);
    });
  });
}
