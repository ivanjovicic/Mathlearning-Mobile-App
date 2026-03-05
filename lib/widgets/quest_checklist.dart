import 'package:flutter/material.dart';
import '../state/settings_provider.dart';

class QuestChecklist extends StatelessWidget {
  final SettingsProvider settings;

  const QuestChecklist({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final entries = <({String label, bool done})>[
      (label: 'Profile setup', done: settings.profileConfigured),
      (label: 'Language selected', done: settings.profileConfigured),
      (label: 'Hints configured', done: settings.hintsConfigured),
      (label: 'Notifications configured', done: settings.notificationsConfigured),
      (label: 'Theme selected', done: settings.themeConfigured),
    ];
    final completed = entries.where((e) => e.done).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Semantics(
          label: 'Setup checklist',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.task_alt_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Setup checklist',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$completed/${entries.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: entries.isEmpty ? 0 : completed / entries.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 12),
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        entry.done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: entry.done ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: entry.done
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

