import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_i18n.dart';
import '../state/auth_provider.dart';
import '../state/progress_provider.dart';
import '../state/settings_provider.dart';
import '../theme/theme_controller.dart';

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
      body:
          Consumer4<
            SettingsProvider,
            ThemeController,
            ProgressProvider,
            AuthProvider
          >(
            builder:
                (context, settings, themeController, progress, auth, child) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SetupHeroCard(
                        completedGoals: settings.completedGoals,
                        completionProgress: settings.completionProgress,
                        setupXp: settings.setupXp,
                        level: progress.level,
                      ),
                      const SizedBox(height: 12),
                      _QuestChecklist(settings: settings),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: t.sectionProfile,
                        icon: Icons.person_outline,
                      ),
                      Card(
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
                            t.profileCardSubtitle,
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
                      ),
                      const SizedBox(height: 8),
                      _LanguageDropdown(settings: settings),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: t.sectionQuizExperience,
                        icon: Icons.extension_outlined,
                      ),
                      _SettingsSwitchTile(
                        title: t.hintsToggleTitle,
                        subtitle: t.hintsToggleSubtitle,
                        value: settings.hintsEnabled,
                        icon: Icons.lightbulb_outline,
                        onChanged: settings.setHintsEnabled,
                      ),
                      _SettingsSwitchTile(
                        title: 'Formula',
                        subtitle: t.formulaToggleSubtitle,
                        value: settings.formulaHintEnabled,
                        icon: Icons.functions,
                        enabled: settings.hintsEnabled,
                        onChanged: settings.setFormulaHintEnabled,
                      ),
                      _SettingsSwitchTile(
                        title: t.clueToggleTitle,
                        subtitle: t.clueToggleSubtitle,
                        value: settings.clueHintEnabled,
                        icon: Icons.tips_and_updates_outlined,
                        enabled: settings.hintsEnabled,
                        onChanged: settings.setClueHintEnabled,
                      ),
                      _SettingsSwitchTile(
                        title: t.eliminateToggleTitle,
                        subtitle: t.eliminateToggleSubtitle,
                        value: settings.eliminateHintEnabled,
                        icon: Icons.filter_list_off,
                        enabled: settings.hintsEnabled,
                        onChanged: settings.setEliminateHintEnabled,
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: t.sectionNotifications,
                        icon: Icons.notifications_outlined,
                      ),
                      _SettingsSwitchTile(
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
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: t.sectionThemeAndApp,
                        icon: Icons.palette_outlined,
                      ),
                      _ThemeModeQuickSwitch(
                        themeController: themeController,
                        onThemePicked: () {
                          settings.markThemeConfigured();
                        },
                      ),
                      const SizedBox(height: 8),
                      _ThemeDropdown(
                        themeController: themeController,
                        onThemePicked: () {
                          settings.markThemeConfigured();
                        },
                      ),
                      const SizedBox(height: 8),
                      Card(
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
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: t.sectionAudioHaptics,
                        icon: Icons.volume_up_outlined,
                      ),
                      _SettingsSwitchTile(
                        title: t.soundEffectsTitle,
                        subtitle: t.soundEffectsSubtitle,
                        value: settings.soundEnabled,
                        icon: Icons.music_note_outlined,
                        onChanged: settings.setSoundEnabled,
                      ),
                      _SettingsSwitchTile(
                        title: t.vibrationTitle,
                        subtitle: t.vibrationSubtitle,
                        value: settings.vibrationEnabled,
                        icon: Icons.vibration,
                        onChanged: settings.setVibrationEnabled,
                      ),
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

  static String _initialFor(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'M';
    return text.substring(0, 1).toUpperCase();
  }
}

class _SetupHeroCard extends StatelessWidget {
  final int completedGoals;
  final double completionProgress;
  final int setupXp;
  final int level;

  const _SetupHeroCard({
    required this.completedGoals,
    required this.completionProgress,
    required this.setupXp,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  t.settingsQuest,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('+$setupXp XP'),
                  avatar: const Icon(Icons.stars, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t.levelMissionProgress(
                level,
                completedGoals,
                SettingsProvider.totalGoals,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 350),
              tween: Tween<double>(begin: 0, end: completionProgress),
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.18,
                    ),
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestChecklist extends StatelessWidget {
  final SettingsProvider settings;

  const _QuestChecklist({required this.settings});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Card(
      child: Column(
        children: [
          _QuestTile(
            icon: Icons.person_outline,
            title: t.profileSetupQuest,
            done: settings.profileConfigured,
          ),
          _QuestTile(
            icon: Icons.notifications_active_outlined,
            title: t.reminderDecisionQuest,
            done: settings.notificationsConfigured,
          ),
          _QuestTile(
            icon: Icons.palette_outlined,
            title: t.themeChoiceQuest,
            done: settings.themeConfigured,
          ),
          _QuestTile(
            icon: Icons.lightbulb_outline,
            title: t.hintsPrefQuest,
            done: settings.hintsConfigured,
          ),
          _QuestTile(
            icon: Icons.volume_up_outlined,
            title: t.soundVibrationQuest,
            done: settings.feedbackConfigured,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool done;
  final bool isLast;

  const _QuestTile({
    required this.icon,
    required this.title,
    required this.done,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: done ? colorScheme.tertiary : colorScheme.onSurface,
      ),
      title: Text(title),
      trailing: Icon(
        done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: done ? colorScheme.tertiary : colorScheme.outline,
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      shape: isLast
          ? null
          : Border(
              bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.6),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final bool enabled;
  final Future<void> Function(bool) onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: enabled
            ? (nextValue) {
                onChanged(nextValue);
              }
            : null,
        secondary: Icon(
          icon,
          color: enabled ? colorScheme.primary : colorScheme.outline,
        ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final SettingsProvider settings;

  const _LanguageDropdown({required this.settings});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DropdownButtonFormField<AppLanguage>(
          initialValue: settings.language,
          decoration: InputDecoration(
            labelText: t.languageLabel,
            prefixIcon: const Icon(Icons.language),
          ),
          items: AppLanguage.values
              .map(
                (language) => DropdownMenuItem<AppLanguage>(
                  value: language,
                  child: Text(language.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              settings.setLanguage(value);
            }
          },
        ),
      ),
    );
  }
}

class _ThemeModeQuickSwitch extends StatelessWidget {
  final ThemeController themeController;
  final VoidCallback onThemePicked;

  const _ThemeModeQuickSwitch({
    required this.themeController,
    required this.onThemePicked,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDark = _isDark(themeController.currentType);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.darkLightMode,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    selected: !isDark,
                    avatar: const Icon(Icons.light_mode_outlined, size: 18),
                    label: Text(t.light),
                    onSelected: (selected) {
                      if (!selected) return;
                      themeController.setTheme(AppThemeType.minimal, context);
                      onThemePicked();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    selected: isDark,
                    avatar: const Icon(Icons.dark_mode_outlined, size: 18),
                    label: Text(t.dark),
                    onSelected: (selected) {
                      if (!selected) return;
                      themeController.setTheme(AppThemeType.sciFi, context);
                      onThemePicked();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t.quickLightHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isDark(AppThemeType type) {
    return type == AppThemeType.sciFi || type == AppThemeType.retro;
  }
}

class _ThemeDropdown extends StatelessWidget {
  final ThemeController themeController;
  final VoidCallback onThemePicked;

  const _ThemeDropdown({
    required this.themeController,
    required this.onThemePicked,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DropdownButtonFormField<AppThemeType>(
          initialValue: themeController.currentType,
          decoration: InputDecoration(
            labelText: t.visualTheme,
            prefixIcon: const Icon(Icons.palette_outlined),
          ),
          items: const [
            DropdownMenuItem(value: AppThemeType.sciFi, child: Text('Sci-Fi')),
            DropdownMenuItem(
              value: AppThemeType.fantasy,
              child: Text('Fantasy'),
            ),
            DropdownMenuItem(
              value: AppThemeType.pastel,
              child: Text('Pastel Kids'),
            ),
            DropdownMenuItem(
              value: AppThemeType.minimal,
              child: Text('Minimal Light'),
            ),
            DropdownMenuItem(
              value: AppThemeType.retro,
              child: Text('Retro Pixel'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              themeController.setTheme(value, context);
              onThemePicked();
            }
          },
        ),
      ),
    );
  }
}
