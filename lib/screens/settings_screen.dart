// Refactored SettingsScreen to improve modularity and maintainability
// Extracted reusable components and optimized state management

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_i18n.dart';
import '../state/auth_provider.dart';
import '../state/progress_provider.dart';
import '../state/settings_provider.dart';
import '../theme/theme_controller.dart';
import '../widgets/section_header.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/theme_mode_quick_switch.dart';
import '../widgets/theme_dropdown.dart';
import '../widgets/quest_checklist.dart';
import '../widgets/setup_hero_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
            },
            icon: const Icon(Icons.home_outlined),
            tooltip: t.navHome,
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Consumer4<
          SettingsProvider, ThemeController, ProgressProvider, AuthProvider>(
        builder: (context, settings, themeController, progress, auth, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SetupHeroCard(
                completedGoals: settings.completedGoals,
                completionProgress: settings.completionProgress,
                setupXp: settings.setupXp,
                level: progress.level,
              ),
              const SizedBox(height: 12),
              QuestChecklist(settings: settings),
              const SizedBox(height: 20),
              SectionHeader(
                title: t.sectionProfile,
                icon: Icons.person_outline,
              ),
              _buildProfileCard(context, settings, auth, theme, colorScheme),
              const SizedBox(height: 8),
              LanguageDropdown(settings: settings),
              const SizedBox(height: 20),
              SectionHeader(
                title: t.sectionQuizExperience,
                icon: Icons.extension_outlined,
              ),
              ..._buildQuizExperienceTiles(settings, t),
              const SizedBox(height: 20),
              SectionHeader(
                title: t.sectionNotifications,
                icon: Icons.notifications_outlined,
              ),
              ..._buildNotificationTiles(context, settings, t, colorScheme),
              const SizedBox(height: 20),
              SectionHeader(
                title: t.sectionThemeAndApp,
                icon: Icons.palette_outlined,
              ),
              ThemeModeQuickSwitch(
                themeController: themeController,
                onThemePicked: settings.markThemeConfigured,
              ),
              const SizedBox(height: 8),
              ThemeDropdown(
                themeController: themeController,
                onThemePicked: settings.markThemeConfigured,
              ),
              const SizedBox(height: 8),
              _buildAdvancedThemeCard(context, settings, colorScheme, t),
              const SizedBox(height: 20),
              SectionHeader(
                title: t.sectionAudioHaptics,
                icon: Icons.volume_up_outlined,
              ),
              ..._buildAudioHapticsTiles(settings, t),
              const SizedBox(height: 8),
              if (!settings.dailyReminderEnabled)
                Text(
                  t.dailyTip,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, SettingsProvider settings,
      AuthProvider auth, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text(
            _initialFor(auth.username),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text('@${auth.username ?? 'korisnik'}'),
        subtitle: Text(
          context.t.profileCardSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
        ),
        onTap: () async {
          await settings.markProfileConfigured();
          if (context.mounted) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

  List<Widget> _buildQuizExperienceTiles(SettingsProvider settings, AppI18n t) {
    return [
      SettingsSwitchTile(
        title: t.hintsToggleTitle,
        subtitle: t.hintsToggleSubtitle,
        value: settings.hintsEnabled,
        icon: Icons.lightbulb_outline,
        onChanged: settings.setHintsEnabled,
      ),
      SettingsSwitchTile(
        title: 'Formula',
        subtitle: t.formulaToggleSubtitle,
        value: settings.formulaHintEnabled,
        icon: Icons.functions,
        enabled: settings.hintsEnabled,
        onChanged: settings.setFormulaHintEnabled,
      ),
      SettingsSwitchTile(
        title: t.clueToggleTitle,
        subtitle: t.clueToggleSubtitle,
        value: settings.clueHintEnabled,
        icon: Icons.tips_and_updates_outlined,
        enabled: settings.hintsEnabled,
        onChanged: settings.setClueHintEnabled,
      ),
      SettingsSwitchTile(
        title: t.eliminateToggleTitle,
        subtitle: t.eliminateToggleSubtitle,
        value: settings.eliminateHintEnabled,
        icon: Icons.filter_list_off,
        enabled: settings.hintsEnabled,
        onChanged: settings.setEliminateHintEnabled,
      ),
    ];
  }

  List<Widget> _buildNotificationTiles(BuildContext context,
      SettingsProvider settings, AppI18n t, ColorScheme colorScheme) {
    return [
      SettingsSwitchTile(
        title: t.dailyReminderTitle,
        subtitle: t.dailyReminderSubtitle,
        value: settings.dailyReminderEnabled,
        icon: Icons.alarm,
        onChanged: (value) async {
          await settings.setDailyReminderEnabled(value);
          if (!context.mounted) return;
          if (settings.lastReminderPermissionDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.allowNotificationsMessage),
              ),
            );
            settings.clearReminderPermissionStatus();
          }
        },
      ),
      if (settings.dailyReminderEnabled)
        Card(
          child: ListTile(
            leading: Icon(
              Icons.schedule,
              color: colorScheme.secondary,
            ),
            title: Text(t.reminderTime),
            subtitle: Text(
              settings.dailyReminderTime.format(context),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: settings.dailyReminderTime,
              );
              if (picked != null) {
                await settings.setReminderTime(picked);
                if (!context.mounted) return;
                if (settings.lastReminderPermissionDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t.reminderSavedButNoPermission,
                      ),
                    ),
                  );
                  settings.clearReminderPermissionStatus();
                }
              }
            },
          ),
        ),
    ];
  }

  List<Widget> _buildAudioHapticsTiles(SettingsProvider settings, AppI18n t) {
    return [
      SettingsSwitchTile(
        title: t.soundEffectsTitle,
        subtitle: t.soundEffectsSubtitle,
        value: settings.soundEnabled,
        icon: Icons.music_note_outlined,
        onChanged: settings.setSoundEnabled,
      ),
      SettingsSwitchTile(
        title: t.vibrationTitle,
        subtitle: t.vibrationSubtitle,
        value: settings.vibrationEnabled,
        icon: Icons.vibration,
        onChanged: settings.setVibrationEnabled,
      ),
    ];
  }

  Widget _buildAdvancedThemeCard(BuildContext context,
      SettingsProvider settings, ColorScheme colorScheme, AppI18n t) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.auto_awesome_outlined,
          color: colorScheme.primary,
        ),
        title: Text(t.advancedThemeTitle),
        subtitle: Text(t.advancedThemeSubtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
        ),
        onTap: () async {
          await settings.markThemeConfigured();
          if (context.mounted) {
            Navigator.pushNamed(context, '/themes');
          }
        },
      ),
    );
  }

  static String _initialFor(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'M';
    return text.substring(0, 1).toUpperCase();
  }
}
