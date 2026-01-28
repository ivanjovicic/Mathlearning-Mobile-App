import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/leaderboard_provider.dart';
import '../state/auth_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  String range = "weekly"; // weekly | allTime

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final provider = Provider.of<LeaderboardProvider>(context, listen: false);

      provider.loadGlobal(range);
      provider.loadFriends(range);
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = Provider.of<LeaderboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "🏆 Leaderboard",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Global"),
              Tab(text: "Friends"),
            ],
          ),
          actions: [
            // weekly / allTime switch
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF1E1E2E),
                value: range,
                items: const [
                  DropdownMenuItem(
                    value: "weekly",
                    child: Text(
                      "Weekly",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "allTime",
                    child: Text(
                      "All time",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => range = v);

                  leaderboard.loadGlobal(v);
                  leaderboard.loadFriends(v);
                },
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildList(
              leaderboard.global,
              leaderboard.isLoading,
              auth.userId != null ? int.tryParse(auth.userId!) : null,
            ),
            _buildList(
              leaderboard.friends,
              leaderboard.isLoading,
              auth.userId != null ? int.tryParse(auth.userId!) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<LeaderboardEntry> items, bool loading, int? myUserId) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          "Nema podataka.",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        return _buildRow(items[i], items[i].userId == myUserId);
      },
    );
  }

  Widget _buildRow(LeaderboardEntry e, bool isMe) {
    Color color = isMe ? Colors.greenAccent : Colors.white;
    Color bg = isMe
        ? Colors.greenAccent.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? Colors.greenAccent
              : Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Rank medal
          _rankIcon(e.rank),

          const SizedBox(width: 14),

          // Name + stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Lvl ${e.level} • XP ${e.xp} • 🔥 ${e.streak}",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankIcon(int rank) {
    switch (rank) {
      case 1:
        return const Text("🥇", style: TextStyle(fontSize: 32));
      case 2:
        return const Text("🥈", style: TextStyle(fontSize: 32));
      case 3:
        return const Text("🥉", style: TextStyle(fontSize: 32));
      default:
        return Text(
          "$rank",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }
}
