import 'package:flutter/material.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

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
      home: home,
      routes: routes,
    ),
  );
}

