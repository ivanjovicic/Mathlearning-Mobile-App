import 'package:flutter/widgets.dart';

extension OverlaySafetyContext on BuildContext {
  String? safeTooltip(String? message) {
    final value = message?.trim();
    if (value == null || value.isEmpty) return null;
    return Overlay.maybeOf(this, rootOverlay: true) != null ? value : null;
  }
}
