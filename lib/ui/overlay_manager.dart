import 'package:flutter/material.dart';

/// Manages a queue of global overlay entries above all shell content.
///
/// Placed as an InheritedWidget inside AppShell so any descendant can
/// call OverlayManager.of(context).show(...) to present a transient overlay.
class OverlayManager extends InheritedWidget {
  const OverlayManager({
    super.key,
    required this.notifier,
    required super.child,
  });

  final OverlayManagerNotifier notifier;

  static OverlayManager? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<OverlayManager>();
  }

  static OverlayManagerNotifier? of(BuildContext context) {
    return maybeOf(context)?.notifier;
  }

  @override
  bool updateShouldNotify(OverlayManager oldWidget) =>
      notifier != oldWidget.notifier;
}

/// Holds and broadcasts the currently active overlay widget (if any).
class OverlayManagerNotifier extends ChangeNotifier {
  Widget? _activeOverlay;

  Widget? get activeOverlay => _activeOverlay;

  /// Display [overlay] above all shell content.
  void show(Widget overlay) {
    _activeOverlay = overlay;
    notifyListeners();
  }

  /// Remove the active overlay.
  void dismiss() {
    _activeOverlay = null;
    notifyListeners();
  }
}
