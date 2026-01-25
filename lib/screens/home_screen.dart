import 'package:flutter/material.dart';
import 'package:mathlearning/widgets/animated_xp_bar.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../state/progress_provider.dart';
import '../state/coin_provider.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/offline_status_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final progress = Provider.of<ProgressProvider>(context, listen: false);
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final coinProvider = Provider.of<CoinProvider>(context, listen: false);
        
        // Set token for progress provider from secure auth
        progress.token = auth.token;
        
        // Load coins data
        coinProvider.loadCoinsAndHints();
        
        // Set up level-up callback
        progress.onLevelUp = () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => LevelUpAnimation(
              level: progress.level,
              onFinished: () {
                Navigator.pop(context);
              },
            ),
          );
        };
        
        progress.loadProgress(); // GET /progress/overview
        progress.loadTopics();   // GET /progress/topics
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<ProgressProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline Status Widget
              const Align(
                alignment: Alignment.topRight,
                child: OfflineStatusWidget(),
              ),
              
              // TOP BAR: avatar + streak + badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "👤 ${auth.username}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, "/badges"),
                        icon: const Text("🏅", style: TextStyle(fontSize: 28)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, "/heatmap"),
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, "/profile"),
                        icon: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("🔥 ", style: TextStyle(fontSize: 30),
                      ),
                      Text(
                        "${progress.streak} days",
                        style: TextStyle(
                          color: Colors.orange.shade300,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Coins display
                      Consumer<CoinProvider>(
                        builder: (context, coinProvider, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on, size: 16, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  '${coinProvider.coins}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 25),

              // LEVEL + XP
              Text(
                "Level ${progress.level}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Text(
                    "⭐",
                    style: TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${progress.xp} / ${progress.xpToNextLevel} XP",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  )
                ],
              ),

              const SizedBox(height: 10),

              // XP BAR
              AnimatedXpBar(
                currentXp: progress.xp,
                maxXp: progress.xpToNextLevel,
              ),

              const SizedBox(height: 30),

              // DAILY GOAL
              Text(
                "🎯 Dnevni cilj: 20 pitanja",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: (progress.totalAttempts % 20) / 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    Colors.greenAccent.shade400,
                  ),
                  minHeight: 12,
                ),
              ),

              const SizedBox(height: 30),

              // SECTION HEADER
              Text(
                "📚 Teme za učenje",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // TOPICS LIST
              Expanded(
                child: ListView.builder(
                  itemCount: progress.topics.length,
                  itemBuilder: (context, i) {
                    final t = progress.topics[i];

                    bool locked = progress.level < t.requiredLevel;

                    return GestureDetector(
                      onTap: locked
                          ? null
                          : () {
                              Navigator.pushNamed(context, "/quiz",
                                  arguments: t.topicId);
                            },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: locked
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: locked
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.greenAccent.shade400,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              locked ? Icons.lock : Icons.play_circle_fill,
                              color: locked
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.greenAccent,
                              size: 34,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "${t.name} (Level ${t.requiredLevel})",
                                style: TextStyle(
                                  color: locked
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow.shade600,
        child: const Icon(Icons.star, color: Colors.white),
        onPressed: () {
          progress.addXP(95); // Add XP to trigger level-up
        },
      ),
    );
  }
}
