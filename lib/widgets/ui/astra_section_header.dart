import 'package:flutter/material.dart';

import '../../theme/theme_extensions/theme_context.dart';

/// Consistent section header used across all screens.
///
/// Displays a [title] with an optional [trailing] action widget.
class AstraSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const AstraSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: context.spacing.s),
      child: Semantics(
        header: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
