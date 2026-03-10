import 'package:flutter/material.dart';

class AstraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;

  const AstraAppBar({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  cs.primary,
                  cs.secondary,
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ],
      ),
      actions: [
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: trailing!,
          ),
      ],
      backgroundColor: Colors.transparent,
    );
  }
}
