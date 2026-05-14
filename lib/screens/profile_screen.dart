import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cosmetic_target.dart';
import '../models/social_cosmetic_loadout.dart';
import '../navigation/app_routes.dart';
import '../navigation/navigation_extensions.dart';
import '../services/user_service.dart';
import '../state/avatar_provider.dart';
import '../state/auth_provider.dart';
import '../state/badge_provider.dart';
import '../state/chase_race_provider.dart';
import '../state/cosmetic_target_provider.dart';
import '../state/progress_provider.dart';
import '../state/player_identity_provider.dart';
import '../state/season_provider.dart';
import '../state/weekly_featured_provider.dart';
import '../utils/overlay_safety.dart';
import '../widgets/animated_xp_bar.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/cosmetic_visuals.dart';
import '../widgets/chase_race_panel.dart';
import '../widgets/cosmetic_target_chip.dart';
import '../widgets/social_cosmetic_avatar.dart';
import '../widgets/theme_accessibility_mini_preview.dart';
import '../widgets/identity_showcase_section.dart';
import '../widgets/ui/app_section.dart';
import '../widgets/weekly_featured_flair_chip.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = context.watch<ProgressProvider>();
    final badges = context.watch<BadgeProvider>().badges;
    final auth = context.watch<AuthProvider>();
    final avatar = context.watch<AvatarProvider>();
    final target = _maybeWatch<CosmeticTargetProvider>(context)?.target;
    final weekly = _maybeWatch<WeeklyFeaturedProvider>(context);
    if (weekly != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        weekly.refreshCompletionFromInventory(avatar.inventory);
      });
    }
    final season = _maybeWatch<SeasonProvider>(context);
    final identity = _maybeWatch<PlayerIdentityProvider>(context);
    if (identity != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        identity.refresh(
          inventory: avatar.inventory,
          catalog: avatar.catalog,
          currentStreak: progress.streak,
          totalAttempts: progress.totalAttempts,
          seasonCompletionPercent: season?.completionPercent ?? 0,
          completedSeasonName:
              (season?.completionPercent ?? 0) >= 100 ? season?.season?.name : null,
          completedSeasonId:
              (season?.completionPercent ?? 0) >= 100 ? season?.season?.seasonId : null,
        );
      });
    }
    final socialLoadout = SocialCosmeticLoadout.fromLocal(
      userId: auth.userId ?? 'local',
      avatar: avatar.avatarConfig,
      inventory: avatar.inventory,
      catalog: avatar.catalog,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<_ProfileMenuAction>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            tooltip: context.safeTooltip('Meni'),
            onSelected: (value) => _onMenuAction(context, value, auth),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _ProfileMenuAction.settings,
                child: _MenuItem(
                  icon: Icons.settings_outlined,
                  text: 'Podesavanja',
                ),
              ),
              const PopupMenuItem(
                value: _ProfileMenuAction.themes,
                child: _MenuItem(
                  icon: Icons.palette_outlined,
                  text: 'Tema i kretanje',
                ),
              ),
              const PopupMenuItem(
                value: _ProfileMenuAction.userSearch,
                child: _MenuItem(
                  icon: Icons.search,
                  text: 'Pretraga korisnika',
                ),
              ),
              const PopupMenuItem(
                value: _ProfileMenuAction.editProfile,
                child: _MenuItem(
                  icon: Icons.edit_outlined,
                  text: 'Izmeni profil',
                ),
              ),
              const PopupMenuItem(
                value: _ProfileMenuAction.customizeAvatar,
                child: _MenuItem(
                  icon: Icons.face_retouching_natural,
                  text: 'Prilagodi avatar',
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: colorScheme.error),
                    const SizedBox(width: 10),
                    Text('Odjava', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 +
              MediaQuery.of(context).padding.bottom +
              kBottomNavigationBarHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProfileHeader(username: auth.username, progress: progress),
            if (weekly?.completedActiveSet == true &&
                weekly?.activeSet != null) ...[
              const SizedBox(height: 10),
              WeeklyFeaturedFlairChip(
                label: weekly!.activeSet!.profileFlair,
                maxWidth: 240,
              ),
            ],
            const SizedBox(height: 16),
            const ThemeAccessibilityMiniPreview(
              title: 'Profil: pregled pristupacnosti',
              compact: true,
            ),
            const SizedBox(height: 16),
            AppSection(
              title: 'Cosmetic showcase',
              padding: const EdgeInsets.only(bottom: 16),
              child: _CosmeticShowcase(
                userId: auth.userId ?? 'local',
                displayName: auth.username ?? 'Korisnik',
                loadout: socialLoadout,
                target: target,
              ),
            ),
            _ChaseRaceSectionForProfile(
              userId: auth.userId ?? 'local',
            ),
            if (identity != null) ...[
              const SizedBox(height: 16),
              AppSection(
                title: 'Player Identity',
                padding: const EdgeInsets.only(bottom: 16),
                child: IdentityShowcaseSection(
                  userId: auth.userId ?? 'local',
                ),
              ),
            ],
            AppSection(
              title: 'Brze opcije',
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.rate_review_outlined,
                        color: colorScheme.primary,
                      ),
                      title: const Text('My Feedback'),
                      subtitle: const Text('Pregled poslatog UX/UI feedback-a'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: context.openFeedback,
                    ),
                  ),
                ],
              ),
            ),
            AppSection(
              title: 'Statistika igraca',
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildRankCard(context, progress),
                  const SizedBox(height: 12),
                  _buildStreakCard(context, progress),
                ],
              ),
            ),
            AppSection(
              title: 'Bedzevi',
              padding: EdgeInsets.zero,
              child: _buildBadgeList(context, badges),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenuAction(
    BuildContext context,
    _ProfileMenuAction value,
    AuthProvider auth,
  ) async {
    switch (value) {
      case _ProfileMenuAction.settings:
        context.openSettings();
        return;
      case _ProfileMenuAction.themes:
        context.openThemes();
        return;
      case _ProfileMenuAction.userSearch:
        context.openUserSearch();
        return;
      case _ProfileMenuAction.editProfile:
        _showEditProfileDialog(context);
        return;
      case _ProfileMenuAction.customizeAvatar:
        context.openAvatarCustomization();
        return;
      case _ProfileMenuAction.logout:
        await auth.logout();
        if (!context.mounted) return;
        const LoginRoute().go(context);
        return;
    }
  }

  Widget _buildRankCard(BuildContext context, ProgressProvider progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rank = _calculateRank(progress.level, progress.xp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor.withAlpha((0.08 * 255).round()),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rang',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  fontSize: 16,
                ),
              ),
              Text(
                '$rank',
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor.withAlpha((0.08 * 255).round()),
        border: Border.all(color: colorScheme.secondary, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Niz',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  fontSize: 16,
                ),
              ),
              Text(
                '${progress.streak} dana',
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

    if (badges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withAlpha((0.08 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          'Jos uvek nema bedzeva. Odigraj jos kvizova!',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final badgeListHeight = (130.0 * scale).clamp(130.0, 180.0).toDouble();

    return SizedBox(
      height: badgeListHeight,
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
                Text(b.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 2),
                Text(
                  b.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: b.unlocked
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withAlpha((0.4 * 255).round()),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  int _calculateRank(int level, int xp) {
    return level * 100 + xp ~/ 10;
  }

  T? _maybeWatch<T>(BuildContext context) {
    try {
      return context.watch<T>();
    } catch (_) {
      return null;
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final userService = UserService.instance;
    final displayNameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          insetPadding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
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
                          content: const Text('Profil je uspesno azuriran!'),
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

/// Shows the current user's chase race rank on their profile.
/// Only rendered when there is an active race with competitors.
class _ChaseRaceSectionForProfile extends StatelessWidget {
  const _ChaseRaceSectionForProfile({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    ChaseRaceProvider provider;
    try {
      provider = context.watch<ChaseRaceProvider>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final race = provider.race;
    if (race == null || !race.hasCompetitors) return const SizedBox.shrink();

    final myEntry = provider.myEntry;
    if (myEntry == null) return const SizedBox.shrink();

    final color = CosmeticVisuals.rarityColor(race.itemRarity);
    final isFirst = provider.isFirstFinisher(userId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppSection(
        title: 'Chase Race',
        padding: EdgeInsets.zero,
        child: Container(
          key: const Key('profile_chase_race_section'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      race.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFirst
                          ? 'First to Unlock! 🏆'
                          : 'Race rank: #${myEntry.rank} of ${race.participants.length}',
                      key: const Key('profile_race_rank_label'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const Key('profile_view_race_button'),
                onPressed: () => showChaseRaceSheet(context),
                style: TextButton.styleFrom(foregroundColor: color),
                child: const Text('View race'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CosmeticShowcase extends StatelessWidget {
  const _CosmeticShowcase({
    required this.userId,
    required this.displayName,
    required this.loadout,
    this.target,
  });

  final String userId;
  final String displayName;
  final SocialCosmeticLoadout loadout;
  final CosmeticTarget? target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              SocialCosmeticAvatar(
                userId: userId,
                displayName: displayName,
                loadout: loadout,
                size: 74,
                isCurrentUser: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loadout.hasEquippedCosmetics
                          ? 'Equipped cosmetics'
                          : 'Default avatar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (loadout.hasEquippedCosmetics)
                      Semantics(
                        label: _equippedSummary(loadout),
                        child: _EquippedItemLabels(loadout: loadout),
                      )
                    else
                      Text(
                        'Unlock and equip frames, trails, and gear to show off here.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (target != null) ...[
          const SizedBox(height: 10),
          CosmeticTargetChip(target: target!),
        ],
        const SizedBox(height: 12),
        Text(
          'Recent unlocks',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        RecentUnlocksStrip(
          unlocks: loadout.recentRareUnlocks,
          emptyText:
              'No cosmetic unlocks yet. Daily Run chests can change that.',
        ),
      ],
    );
  }

  String _equippedSummary(SocialCosmeticLoadout loadout) {
    return loadout.equippedItemLabels.map((e) => e.name).join(' · ');
  }
}

class _EquippedItemLabels extends StatelessWidget {
  const _EquippedItemLabels({required this.loadout});

  final SocialCosmeticLoadout loadout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = loadout.equippedItemLabels;
    if (labels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: labels.map((label) {
        final rarityColor = label.rarity != null
            ? CosmeticVisuals.rarityColor(label.rarity!)
            : null;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rarityColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rarityColor,
                  boxShadow: [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: rarityColor ?? theme.colorScheme.onSurfaceVariant,
                fontWeight: rarityColor != null
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.username, required this.progress});

  final String? username;
  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: context.openAvatarCustomization,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const AvatarWidget(size: 110, showFrame: true),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '@${username ?? 'Korisnik'}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: colorScheme.onSurface.withAlpha((0.8 * 255).round()),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Nivo ${progress.level}',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedXpBar(currentXp: progress.xp, maxXp: progress.xpToNextLevel),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon), const SizedBox(width: 10), Text(text)]);
  }
}

enum _ProfileMenuAction {
  settings,
  themes,
  userSearch,
  editProfile,
  customizeAvatar,
  logout,
}
