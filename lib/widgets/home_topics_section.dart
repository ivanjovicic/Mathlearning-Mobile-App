import 'package:flutter/material.dart';
import '../models/topic_item.dart';

class HomeTopicsSection extends StatelessWidget {
  final List<TopicItem> topics;

  const HomeTopicsSection({super.key, required this.topics});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          "Your Topics",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        // Sve teme (locked + unlocked)
        ...topics.map((t) => _topicTile(context, t)),
      ],
    );
  }

  Widget _topicTile(BuildContext context, TopicItem t) {
    return GestureDetector(
      onTap: t.locked
          ? null
          : () {
              Navigator.pushNamed(context, '/quiz', arguments: t.id);
            },
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
              // Ikonica
              Icon(t.icon, color: Colors.white, size: 32),
              const SizedBox(width: 15),

              // Naziv + accuracy ili locked text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Naziv + lock icon
                    Row(
                      children: [
                        Text(
                          t.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (t.locked)
                          const Icon(Icons.lock, color: Colors.white, size: 18),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Ako je unlocked → prikazujemo accuracy bar
                    if (!t.locked) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: t.accuracy / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${t.accuracy.toStringAsFixed(1)}% accuracy",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],

                    // Ako je locked → tooltip
                    if (t.locked)
                      Text(
                        "Complete previous topic to unlock",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),

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
