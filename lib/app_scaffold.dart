import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  RouteInformationProvider? _routeInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = GoRouter.of(context).routeInformationProvider;
    if (identical(_routeInfo, provider)) return;
    _routeInfo?.removeListener(_handleRouteChange);
    _routeInfo = provider;
    _routeInfo?.addListener(_handleRouteChange);
  }

  @override
  void dispose() {
    _routeInfo?.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _handleRouteChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getSelectedIndex(),
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex() {
    final location = _routeInfo?.value.uri.toString() ?? '';
    if (location.startsWith('/home')) {
      return 0;
    } else if (location.startsWith('/leaderboard')) {
      return 1;
    } else if (location.startsWith('/settings')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/leaderboard');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}
