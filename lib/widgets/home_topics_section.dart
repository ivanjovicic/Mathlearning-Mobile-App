import 'package:flutter/material.dart';

import '../models/topic_item.dart';
import '../navigation/navigation_extensions.dart';

class HomeTopicsSection extends StatelessWidget {
  final List<TopicItem> topics;

  const HomeTopicsSection({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          "Your Topics",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...topics.map((t) => _topicTile(context, t)),
      ],
    );
  }

  Widget _topicTile(BuildContext context, TopicItem t) {
    final colorScheme = Theme.of(context).colorScheme;
    final onCardColor =
        ThemeData.estimateBrightnessForColor(t.color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: t.locked ? null : () => context.pushQuiz(topicId: t.id),
        child: Opacity(
          opacity: t.locked ? 0.45 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!t.locked)
                  BoxShadow(
                    color: t.color.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Row(
              children: [
                Icon(t.icon, color: onCardColor, size: 32),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            t.name,
                            style: TextStyle(
                              color: onCardColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (t.locked)
                            Icon(Icons.lock, color: onCardColor, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!t.locked) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: t.accuracy / 100,
                            minHeight: 6,
                            backgroundColor: onCardColor.withValues(
                              alpha: 0.24,
                            ),
                            color: colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${t.accuracy.toStringAsFixed(1)}% accuracy",
                          style: TextStyle(
                            color: onCardColor.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (t.locked)
                        Text(
                          "Complete previous topic to unlock",
                          style: TextStyle(
                            color: onCardColor.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!t.locked)
                  Icon(Icons.arrow_forward_ios, color: onCardColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
