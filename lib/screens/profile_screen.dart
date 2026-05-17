import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_i18n.dart';
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
    final t = context.t;
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
          t.sectionProfile,
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
            tooltip: context.safeTooltip(t.profileMenu),
            onSelected: (value) => _onMenuAction(context, value, auth),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ProfileMenuAction.settings,
                child: _MenuItem(
                  icon: Icons.settings_outlined,
                  text: t.sectionSettings,
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.themes,
                child: _MenuItem(
                  icon: Icons.palette_outlined,
                  text: t.sectionThemeAndMotion,
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.userSearch,
                child: _MenuItem(
                  icon: Icons.search,
                  text: t.userSearch,
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.editProfile,
                child: _MenuItem(
                  icon: Icons.edit_outlined,
                  text: t.editProfile,
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.customizeAvatar,
                child: _MenuItem(
                  icon: Icons.face_retouching_natural,
                  text: t.customizeAvatar,
                ),
              ),
              PopupMenuItem(
                value: _ProfileMenuAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: colorScheme.error),
                    const SizedBox(width: 10),
                    Text(t.logout, style: TextStyle(color: colorScheme.error)),
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
            ThemeAccessibilityMiniPreview(
              title: t.profileAccessibilityPreview,
              compact: true,
            ),
            const SizedBox(height: 16),
            AppSection(
              title: t.cosmeticShowcase,
              padding: const EdgeInsets.only(bottom: 16),
              child: _CosmeticShowcase(
                userId: auth.userId ?? 'local',
                displayName: auth.username ?? t.defaultUser,
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
                title: t.playerIdentity,
                padding: const EdgeInsets.only(bottom: 16),
                child: IdentityShowcaseSection(
                  userId: auth.userId ?? 'local',
                ),
              ),
            ],
            AppSection(
              title: t.quickOptions,
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.rate_review_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Text(t.myFeedback),
                      subtitle: Text(t.feedbackHistorySubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: context.openFeedback,
                    ),
                  ),
                ],
              ),
            ),
            AppSection(
              title: t.playerStats,
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
              title: t.badges,
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
    final t = context.t;
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
                t.rank,
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
    final t = context.t;

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
                t.qsStreak,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  fontSize: 16,
                ),
              ),
              Text(
                t.streakDays(progress.streak),
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
    final t = context.t;

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
          t.noBadgesYet,
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
    final t = context.t;
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
          title: Text(t.editProfileDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: t.displayName,
                  hintText: t.enterNewDisplayName,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: t.emailLabel,
                  hintText: t.enterNewEmail,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.cancel),
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
                          content: Text(t.profileUpdatedSuccess),
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
                          content: Text(
                            t.profileUpdateFailedWithError(e.toString()),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(t.save),
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
    final t = context.t;
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
        title: t.chaseRace,
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
                          ? t.firstToUnlock
                          : t.raceRank(myEntry.rank, race.participants.length),
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
                child: Text(t.viewRace),
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
    final t = context.t;

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
                          ? t.equippedCosmetics
                          : t.defaultAvatar,
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
                        t.unlockCosmeticsHint,
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
          t.recentUnlocks,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        RecentUnlocksStrip(
          unlocks: loadout.recentRareUnlocks,
          emptyText: t.noCosmeticUnlocksYet,
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
    final t = context.t;

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
          '@${username ?? t.defaultUser}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            color: colorScheme.onSurface.withAlpha((0.8 * 255).round()),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t.levelWithValue(progress.level),
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
