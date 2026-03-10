import 'package:flutter/material.dart';

import '../../theme/tokens/breakpoint_tokens.dart';

/// A responsive wrapper that constrains content width and centers it
/// based on the current window-size class.
///
/// Provides optional different layouts for each breakpoint via [builder].
///
/// Simple usage (max-width centered):
/// ```dart
/// ResponsiveLayout(child: MyContent())
/// ```
///
/// Multi-layout usage:
/// ```dart
/// ResponsiveLayout.builder(
///   compact: (ctx, w) => SingleColumnLayout(),
///   medium: (ctx, w) => TwoColumnLayout(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget? child;
  final Widget Function(BuildContext context, WindowSize size)? builder;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveLayout({
    super.key,
    required Widget this.child,
    this.maxWidth,
    this.padding,
  }) : builder = null;

  const ResponsiveLayout.builder({
    super.key,
    required Widget Function(BuildContext, WindowSize) this.builder,
    this.maxWidth,
    this.padding,
  }) : child = null;

  @override
  Widget build(BuildContext context) {
    final size = AppBreakpoints.of(context);
    final effectiveMaxWidth = maxWidth ?? AppBreakpoints.contentMaxWidth(context);
    final effectivePadding = padding ?? _defaultPadding(size);

    final content = builder != null ? builder!(context, size) : child!;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: effectivePadding,
          child: content,
        ),
      ),
    );
  }

  static EdgeInsets _defaultPadding(WindowSize size) => switch (size) {
    WindowSize.compact  => const EdgeInsets.symmetric(horizontal: 16),
    WindowSize.medium   => const EdgeInsets.symmetric(horizontal: 24),
    WindowSize.expanded => const EdgeInsets.symmetric(horizontal: 32),
    WindowSize.large    => const EdgeInsets.symmetric(horizontal: 40),
  };
}
