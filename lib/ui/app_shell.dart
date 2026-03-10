import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/theme_controller.dart';
import '../ui/motion_scope.dart';
import '../ui/overlay_manager.dart';
import '../widgets/offline_status_widget.dart';
import '../widgets/global_bug_report_button.dart';

/// The persistent shell wrapping the five main navigation branches.
///
/// Responsibilities:
///   • Single [NavigationBar] driven by [StatefulNavigationShell.currentIndex]
///   • [MotionScope] gating animations for the entire subtree
///   • [OverlayManager] portal for XP popups, achievement toasts, milestones
///   • [OfflineStatusWidget] banner above the nav bar
///   • [GlobalBugReportButton] overlay in bottom-right corner
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final OverlayManagerNotifier _overlayNotifier;

  @override
  void initState() {
    super.initState();
    _overlayNotifier = OverlayManagerNotifier();
  }

  @override
  void dispose() {
    _overlayNotifier.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final reduceMotion =
        themeController.reduceMotion ||
        MediaQuery.of(context).disableAnimations;

    return MotionScope(
      reduce: reduceMotion,
      child: OverlayManager(
        notifier: _overlayNotifier,
        child: Scaffold(
          body: Stack(
            children: [
              // Main branch content
              widget.navigationShell,
              // Global overlay layer for XP popups, achievements, milestones
              ListenableBuilder(
                listenable: _overlayNotifier,
                builder: (context, _) {
                  final overlay = _overlayNotifier.activeOverlay;
                  if (overlay == null) return const SizedBox.shrink();
                  return overlay;
                },
              ),
              // Bug report FAB
              const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 72, right: 8),
                  child: GlobalBugReportButton(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Offline / pending-sync banner
              const OfflineStatusWidget(),
              NavigationBar(
                selectedIndex: widget.navigationShell.currentIndex,
                onDestinationSelected: _onTabTapped,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map_rounded),
                    label: 'Learn',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bolt_outlined),
                    selectedIcon: Icon(Icons.bolt_rounded),
                    label: 'Practice',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    selectedIcon: Icon(Icons.emoji_events_rounded),
                    label: 'Leaderboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
