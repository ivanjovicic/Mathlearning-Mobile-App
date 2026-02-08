import 'package:flutter/widgets.dart';

class RouteTracker extends NavigatorObserver {
  RouteTracker._();
  static final RouteTracker instance = RouteTracker._();

  final ValueNotifier<String> currentRoute = ValueNotifier<String>('unknown');

  String _resolveName(Route<dynamic>? route) {
    if (route == null) {
      return 'unknown';
    }
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return route.runtimeType.toString();
  }

  void _setFrom(Route<dynamic>? route) {
    currentRoute.value = _resolveName(route);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _setFrom(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _setFrom(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _setFrom(newRoute);
  }
}
