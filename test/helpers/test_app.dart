import 'package:flutter/material.dart';
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

