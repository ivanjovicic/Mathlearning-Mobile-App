import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/navigation_extensions.dart';
import '../state/adaptive_provider.dart';
import '../widgets/adaptive_practice_card.dart';
import '../widgets/weak_topic_card.dart';

class AdaptivePracticeScreen extends StatefulWidget {
  const AdaptivePracticeScreen({super.key});

  @override
  State<AdaptivePracticeScreen> createState() => _AdaptivePracticeScreenState();
}

class _AdaptivePracticeScreenState extends State<AdaptivePracticeScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdaptiveProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adaptiveProvider = context.watch<AdaptiveProvider>();
    final practiceData = adaptiveProvider.practiceData;
    final weakTopics = adaptiveProvider.weakTopics;
    final recommendation = adaptiveProvider.recommendation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Practice'),
      ),
      body: Builder(
        builder: (context) {
          if (adaptiveProvider.isLoading && practiceData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adaptiveProvider.error != null && practiceData == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline),
                    const SizedBox(height: 12),
                    Text(
                      adaptiveProvider.error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.read<AdaptiveProvider>().loadDashboard(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (practiceData == null) {
            return const Center(child: Text('No adaptive data available'));
          }

          return RefreshIndicator(
            onRefresh: () => context.read<AdaptiveProvider>().loadDashboard(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                AdaptivePracticeCard(practiceData: practiceData),
                const SizedBox(height: 16),
                Text(
                  'Weak topics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (weakTopics.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No weak topics detected yet.'),
                    ),
                  )
                else
                  ...weakTopics.map((topic) => WeakTopicCard(weakTopic: topic)),
                const SizedBox(height: 16),
                if (recommendation != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next recommendation',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('${recommendation.topic} • ${recommendation.difficulty}'),
                          const SizedBox(height: 4),
                          Text(
                            recommendation.reasoning,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.openQuiz(
                    topicId: practiceData.topicId ?? 1,
                    source: 'adaptive_hub',
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start adaptive practice'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
