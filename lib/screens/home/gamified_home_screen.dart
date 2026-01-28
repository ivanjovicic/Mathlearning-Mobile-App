import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../quiz/pick_topic_screen.dart';
import '../../models/user_profile.dart';
import '../../models/progress_overview.dart';
import '../../models/topic_dto.dart';
import '../../models/topic_item.dart';
import '../../widgets/home_topics_section.dart';

class GamifiedHomeScreen extends StatefulWidget {
  const GamifiedHomeScreen({super.key});

  @override
  State<GamifiedHomeScreen> createState() => _GamifiedHomeScreenState();
}

class _GamifiedHomeScreenState extends State<GamifiedHomeScreen> {
  UserProfile? userProfile;
  ProgressOverview? progressOverview;
  List<TopicDto> topics = [];
  bool loading = true;
  bool _openedTopics = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final api = ApiService();
    final profileData = await api.getUserProfile();
    final overview = await api.getProgressOverview();
    final topicsData = await api.getTopicsProgress();

    final parsedTopics = topicsData != null
        ? (topicsData as List).map((e) => TopicDto.fromJson(e)).toList()
        : <TopicDto>[];

    setState(() {
      userProfile = profileData != null
          ? UserProfile.fromJson(profileData)
          : null;
      progressOverview = overview;
      topics = parsedTopics;
      loading = false;
    });

    // Automatically open PickTopicScreen once, after topics are loaded
    if (!_openedTopics && topics.isNotEmpty) {
      _openedTopics = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final mapped = topics.map((topic) {
          final id = topic.id;
          final name = topic.name;
          final accuracy = topic.accuracy;
          final icon = Icons.auto_stories;
          final color = Colors.primaries[id % Colors.primaries.length];
          final unlocked = topic.unlocked;
          return TopicItem(
            id: id,
            name: name,
            icon: icon,
            color: color,
            accuracy: accuracy,
            locked: !unlocked,
          );
        }).toList();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PickTopicScreen(topics: mapped)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101820),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final xp = userProfile?.xp ?? 0;
    final nextLevelXp = ((userProfile?.level ?? 1) * 100); // primer logike
    final streak = progressOverview?.completedQuizzes ?? 0; // primer logike
    final userName = userProfile?.displayName.isNotEmpty == true
        ? userProfile!.displayName
        : (userProfile?.username ?? "");
    final accuracy = progressOverview?.averageScore ?? 0.0;
    double progress = nextLevelXp > 0 ? xp / nextLevelXp : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Greeting + Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hey $userName 👋",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.amber,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : "?",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // XP card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.shade700,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "XP Progress",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white10,
                        color: Colors.greenAccent,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "$xp / $nextLevelXp XP",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Accuracy: ${accuracy.toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Streak display
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "$streak day streak 🔥",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              Text(
                "Continue learning",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Continue button
              GestureDetector(
                onTap: () async {
                  if (topics.isNotEmpty) {
                    final firstTopic = topics.first;
                    final topicId = firstTopic.id;
                    Navigator.pushNamed(context, '/quiz', arguments: topicId);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.blueAccent,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "▶ Continue last session",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              GestureDetector(
                onTap: () {
                  final mapped = topics.map((topic) {
                    final id = topic.id;
                    final name = topic.name;
                    final accuracy = topic.accuracy;
                    final icon = Icons.auto_stories;
                    final color =
                        Colors.primaries[id % Colors.primaries.length];
                    final unlocked = topic.unlocked;
                    return TopicItem(
                      id: id,
                      name: name,
                      icon: icon,
                      color: color,
                      accuracy: accuracy,
                      locked: !unlocked,
                    );
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PickTopicScreen(topics: mapped),
                    ),
                  );
                },
                child: Text(
                  "Pick a topic",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Topic cards (new reusable widget)
              HomeTopicsSection(
                topics: topics.map((t) {
                  final id = t.id;
                  final name = t.name;
                  final accuracy = t.accuracy;
                  final icon = Icons.auto_stories;
                  final color = Colors.primaries[id % Colors.primaries.length];
                  return TopicItem(
                    id: id,
                    name: name,
                    accuracy: accuracy,
                    locked: !t.unlocked,
                    icon: icon,
                    color: color,
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // _topicCard removed; replaced by HomeTopicsSection usage.
}
