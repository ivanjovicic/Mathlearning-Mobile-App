import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../state/leaderboard_provider.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LeaderboardProvider>(context, listen: false);
      provider.loadGlobal(range);
      provider.loadFriends(range);
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboard = Provider.of<LeaderboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface.withValues(alpha: 0),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "Rang lista",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Globalno"),
              Tab(text: "Prijatelji"),
            ],
          ),
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: colorScheme.surface,
                value: range,
                items: [
                  DropdownMenuItem(
                    value: "weekly",
                    child: Text(
                      "Nedeljno",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "allTime",
                    child: Text(
                      "Ukupno",
                      style: TextStyle(color: colorScheme.onSurface),
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
              colorScheme,
            ),
            _buildList(
              leaderboard.friends,
              leaderboard.isLoading,
              auth.userId != null ? int.tryParse(auth.userId!) : null,
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<LeaderboardEntry> items,
    bool loading,
    int? myUserId,
    ColorScheme colorScheme,
  ) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          "Nema podataka.",
          style: TextStyle(color: colorScheme.onSurface),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        return _buildRow(items[i], items[i].userId == myUserId, colorScheme);
      },
    );
  }

  Widget _buildRow(LeaderboardEntry e, bool isMe, ColorScheme colorScheme) {
    final color = isMe ? colorScheme.primary : colorScheme.onSurface;
    final bg = isMe
        ? colorScheme.primaryContainer.withValues(alpha: 0.45)
        : colorScheme.surface.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? colorScheme.primary : colorScheme.outline,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          _rankIcon(e.rank),
          const SizedBox(width: 14),
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
                  "Nivo ${e.level} | XP ${e.xp} | Niz ${e.streak}",
                  style: TextStyle(
                    color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
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
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }
}
