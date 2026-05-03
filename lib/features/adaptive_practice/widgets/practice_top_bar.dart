import 'package:flutter/material.dart';

class PracticeTopBar extends StatelessWidget {
  const PracticeTopBar({
    super.key,
    required this.skillTitle,
    required this.progress,
    required this.onClosePressed,
  });

  final String skillTitle;
  final double progress;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                skillTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Exit challenge',
              onPressed: onClosePressed,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 10,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}
