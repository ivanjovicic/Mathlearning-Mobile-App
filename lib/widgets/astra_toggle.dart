import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Astra-quality toggle switch with neon glow, animated knob,
/// optional label, and haptic feedback.
class AstraToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final String? label;
  final bool enabled;

  const AstraToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.label,
    this.enabled = true,
  });

  void _toggle() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = activeColor ?? cs.primary;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final opacity = enabled ? 1.0 : 0.4;

    final toggle = Semantics(
      toggled: value,
      enabled: enabled,
      label: label ?? 'Toggle',
      child: GestureDetector(
        onTap: _toggle,
        child: Opacity(
          opacity: opacity,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeInOut,
            width: 58,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: value
                  ? effectiveColor.withValues(alpha: 0.3)
                  : cs.surfaceContainerHighest,
              border: Border.all(
                color: value
                    ? effectiveColor.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
              ],
            ),
            child: AnimatedAlign(
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              duration: duration,
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: duration,
                margin: const EdgeInsets.all(4),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? effectiveColor
                      : Colors.white.withValues(alpha: 0.24),
                  boxShadow: [
                    if (value)
                      BoxShadow(
                        color: effectiveColor.withValues(alpha: 0.55),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (label == null) return toggle;

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              label!,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: opacity),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          toggle,
        ],
      ),
    );
  }
}
