import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/progress_provider.dart';
import '../state/badge_provider.dart';
import '../state/auth_provider.dart';
import '../theme/theme_controller.dart';
import '../widgets/animated_xp_bar.dart';
import '../widgets/theme_accessibility_mini_preview.dart';
// user_service and user_profile imports removed (unused)
import 'user_search_screen.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progress = Provider.of<ProgressProvider>(context);
    final badges = Provider.of<BadgeProvider>(context).badges;
    final auth = Provider.of<AuthProvider>(context);
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "👤 Profil",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, "/settings"),
            icon: Icon(Icons.settings_outlined, color: colorScheme.onSurface),
            tooltip: 'Podesavanja',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, "/themes"),
            icon: Icon(Icons.palette_outlined, color: colorScheme.onSurface),
            tooltip: 'Tema i kretanje',
          ),
          // Search users button
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserSearchScreen(),
                ),
              );
            },
            icon: Icon(Icons.search, color: colorScheme.onSurface),
            tooltip: 'Pretraga korisnika',
          ),
          // Edit profile button
          IconButton(
            onPressed: () => _showEditProfileDialog(context),
            icon: Icon(Icons.edit, color: colorScheme.onSurface),
            tooltip: 'Izmeni profil',
          ),
          // Logout button
          IconButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            icon: Icon(Icons.logout, color: colorScheme.error),
            tooltip: 'Odjava',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.cardColor.withAlpha((0.1 * 255).round()),
                  border: Border.all(color: colorScheme.secondary, width: 3),
                ),
                alignment: Alignment.center,
                child: const Text("🧠", style: TextStyle(fontSize: 70)),
              ),
            ),

            const SizedBox(height: 16),

            // Username
            Text(
              "@${auth.username ?? 'Korisnik'}",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                color: colorScheme.onSurface.withAlpha((0.8 * 255).round()),
              ),
            ),

            const SizedBox(height: 8),

            // Level
            Text(
              "Nivo ${progress.level}",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            // XP bar
            AnimatedXpBar(
              currentXp: progress.xp,
              maxXp: progress.xpToNextLevel,
            ),

            const SizedBox(height: 18),
            const ThemeAccessibilityMiniPreview(
              title: "Profil: pregled pristupacnosti",
              compact: true,
            ),

            const SizedBox(height: 14),
            Card(
              child: SwitchListTile(
                value: themeController.useGamifiedHome,
                onChanged: themeController.setUseGamifiedHome,
                secondary: Icon(
                  Icons.videogame_asset_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text("Gamifikovana pocetna"),
                subtitle: Text(
                  themeController.useGamifiedHome
                      ? "Arena pocetna je ukljucena"
                      : "Klasicna pocetna je ukljucena",
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Rank
            _buildRankCard(context, progress),

            const SizedBox(height: 28),

            // Streak
            _buildStreakCard(context, progress),

            const SizedBox(height: 28),

            // Badges
            _buildBadgeList(context, badges),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard(BuildContext context, ProgressProvider progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    int rank = _calculateRank(progress.level, progress.xp);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor.withAlpha((0.08 * 255).round()),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      child: Row(
        children: [
          const Text("🏆", style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Rang",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  fontSize: 16,
                ),
              ),
              Text(
                "$rank",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, ProgressProvider progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor.withAlpha((0.08 * 255).round()),
        border: Border.all(color: colorScheme.secondary, width: 2),
      ),
      child: Row(
        children: [
          const Text("🔥", style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Niz",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  fontSize: 16,
                ),
              ),
              Text(
                "${progress.streak} dana",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeList(BuildContext context, List badges) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🎖 Bedževi",
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: badges.map((b) {
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: b.unlocked
                      ? theme.cardColor.withAlpha((0.2 * 255).round())
                      : theme.cardColor.withAlpha((0.08 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: b.unlocked
                        ? colorScheme.secondary
                        : theme.cardColor.withAlpha((0.2 * 255).round()),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(b.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(
                      b.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: b.unlocked
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withAlpha(
                                (0.4 * 255).round(),
                              ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  int _calculateRank(int level, int xp) {
    return level * 100 + xp ~/ 10;
  }

  void _showEditProfileDialog(BuildContext context) {
    final userService = UserService.instance;
    final displayNameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izmena profila'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Prikazano ime',
                  hintText: 'Unesi novo prikazano ime',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Imejl',
                  hintText: 'Unesi novi imejl',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Otkazi'),
            ),
            ElevatedButton(
              onPressed: () async {
                final displayName = displayNameController.text.trim();
                final email = emailController.text.trim();

                if (displayName.isNotEmpty || email.isNotEmpty) {
                  try {
                    await userService.updateProfile(
                      displayName: displayName.isNotEmpty ? displayName : null,
                      email: email.isNotEmpty ? email : null,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profil je uspesno azuriran!'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Azuriranje profila nije uspelo: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Sacuvaj'),
            ),
          ],
        );
      },
    ).then((_) {
      displayNameController.dispose();
      emailController.dispose();
    });
  }
}
