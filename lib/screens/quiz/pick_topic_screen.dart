import 'package:flutter/material.dart';

import '../../models/topic_item.dart';
import '../../navigation/navigation_extensions.dart';

class PickTopicScreen extends StatelessWidget {
  final List<TopicItem> topics;

  const PickTopicScreen({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        title: Text(
          "Choose a topic",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: topics.map((t) => _topicCard(context, t)).toList(),
      ),
    );
  }

  Widget _topicCard(BuildContext context, TopicItem t) {
    final colorScheme = Theme.of(context).colorScheme;
    final onCardColor =
        ThemeData.estimateBrightnessForColor(t.color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final progress = t.accuracy / 100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: t.locked ? null : () => context.pushQuiz(topicId: t.id),
        child: Opacity(
          opacity: t.locked ? 0.45 : 1,
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
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
                Icon(t.icon, color: onCardColor, size: 36),
                const SizedBox(width: 20),
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
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (t.locked)
                            Icon(Icons.lock, color: onCardColor, size: 22),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (!t.locked) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (t.locked)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Complete previous topic to unlock",
                            style: TextStyle(
                              color: onCardColor.withValues(alpha: 0.85),
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
