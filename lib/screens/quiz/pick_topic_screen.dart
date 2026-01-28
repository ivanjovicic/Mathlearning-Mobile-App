import 'package:flutter/material.dart';
import '../../models/topic_item.dart';

class PickTopicScreen extends StatelessWidget {
  final List<TopicItem> topics;

  const PickTopicScreen({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Choose a Topic",
          style: TextStyle(
            color: Colors.white,
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
    double progress = t.accuracy / 100;

    return GestureDetector(
      onTap: t.locked
          ? null
          : () {
              Navigator.pushNamed(context, '/quiz', arguments: t.id);
            },
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
              Icon(t.icon, color: Colors.white, size: 36),
              const SizedBox(width: 20),

              // TEXT + ACCURACY
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          t.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (t.locked)
                          const Icon(Icons.lock, color: Colors.white, size: 22),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Accuracy bar (samo ako nije locked)
                    if (!t.locked) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${t.accuracy.toStringAsFixed(1)}% accuracy",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    // Tooltip za zaključane
                    if (t.locked)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Complete previous topic to unlock",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (!t.locked)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// TopicItem model is defined in lib/models/topic_item.dart
