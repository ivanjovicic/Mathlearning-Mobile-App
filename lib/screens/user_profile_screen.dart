import 'package:flutter/material.dart';

import '../models/social_cosmetic_loadout.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../widgets/cosmetic_visuals.dart';
import '../widgets/social_cosmetic_avatar.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    this.profileLoader,
  });

  final String userId;
  final Future<UserProfile?> Function(String userId)? profileLoader;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(covariant UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.profileLoader != widget.profileLoader) {
      _profileFuture = _loadProfile();
    }
  }

  Future<UserProfile?> _loadProfile() {
    final loader =
        widget.profileLoader ?? UserService.instance.getPublicProfile;
    return loader(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final loadout =
              profile?.cosmeticLoadout ?? const SocialCosmeticLoadout();
          final displayName = _displayName(profile, widget.userId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SocialCosmeticAvatar(
                      userId: widget.userId,
                      displayName: displayName,
                      avatarUrl: profile?.avatarUrl,
                      loadout: loadout,
                      size: 82,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              profile == null)
                            Text(
                              'Loading profile...',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          else if (loadout.hasEquippedCosmetics)
                            _EquippedCosmeticsSummary(loadout: loadout)
                          else
                            Text(
                              'No cosmetics equipped yet',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (profile != null) _ProfileStatsSection(profile: profile),
                const SizedBox(height: 20),
                Text(
                  'Recent unlocks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                RecentUnlocksStrip(unlocks: loadout.recentRareUnlocks),
                const SizedBox(height: 20),
                const _MoreStatsComingSoonNote(),
              ],
            ),
          );
        },
      ),
    );
  }

  String _displayName(UserProfile? profile, String userId) {
    if (profile == null) return 'User $userId';
    if (profile.displayName.isNotEmpty) return profile.displayName;
    if (profile.username.isNotEmpty) return profile.username;
    return 'User $userId';
  }
}

class _ProfileStatsSection extends StatelessWidget {
  const _ProfileStatsSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final loadout = profile.cosmeticLoadout;
    final equippedCount = loadout?.equippedItemLabels.length ?? 0;
    final recentUnlockCount = loadout?.recentRareUnlocks.length ?? 0;

    final stats = <({String label, String value, IconData icon})>[
      (
        label: 'XP',
        value: profile.hasXp ? '${profile.xp}' : 'Not available',
        icon: Icons.bolt,
      ),
      (
        label: 'Level',
        value: profile.hasLevel ? '${profile.level}' : 'Not available',
        icon: Icons.military_tech,
      ),
      if (equippedCount > 0)
        (
          label: 'Equipped',
          value: '$equippedCount',
          icon: Icons.checkroom_outlined,
        ),
      if (recentUnlockCount > 0)
        (
          label: 'Unlocks',
          value: '$recentUnlockCount',
          icon: Icons.workspace_premium,
        ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: stats
          .map((s) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    s.value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _MoreStatsComingSoonNote extends StatelessWidget {
  const _MoreStatsComingSoonNote();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        'More stats coming soon.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _EquippedCosmeticsSummary extends StatelessWidget {
  const _EquippedCosmeticsSummary({required this.loadout});

  final SocialCosmeticLoadout loadout;

  @override
  Widget build(BuildContext context) {
    final labels = loadout.equippedItemLabels;
    if (labels.isEmpty) {
      return Text(
        'No cosmetics equipped yet',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: labels
          .map((label) {
            final color = label.rarity == null
                ? Theme.of(context).colorScheme.outline
                : CosmeticVisuals.rarityColor(label.rarity!);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Text(
                label.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: label.rarity == null ? null : color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
