import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:mathlearning/theme/app_scale.dart';

Widget buildTestApp({
  required Widget home,
  required List<SingleChildWidget> providers,
  Map<String, WidgetBuilder> routes = const {},
  ThemeData? theme,
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      theme: theme,
      builder: (context, child) {
        AppScale.init(context);
        return child ?? const SizedBox.shrink();
      },
      home: home,
      routes: routes,
    ),
  );
}

/// Builds a test app with GoRouter support.
/// Use this when the widget under test uses [context.go], [context.push], etc.
Widget buildGoRouterTestApp({
  required List<GoRoute> routes,
  required String initialLocation,
  required List<SingleChildWidget> providers,
  ThemeData? theme,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: routes,
  );
  return MultiProvider(
    providers: providers,
    child: MaterialApp.router(
      theme: theme,
      routerConfig: router,
      builder: (context, child) {
        AppScale.init(context);
        return child ?? const SizedBox.shrink();
      },
    ),
  );
}

