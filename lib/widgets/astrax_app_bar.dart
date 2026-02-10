import 'package:flutter/material.dart';
import '../theme/astrax_theme.dart';

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
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AstraXTheme.neonBlue,
                  AstraXTheme.neonPurple,
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
