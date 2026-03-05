import 'package:flutter/material.dart';
import '../state/settings_provider.dart';

class LanguageDropdown extends StatelessWidget {
  final SettingsProvider settings;

  const LanguageDropdown({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Icon(Icons.language_rounded, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<AppLanguage>(
                initialValue: settings.language,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Language',
                ),
                items: AppLanguage.values
                    .map(
                      (lang) => DropdownMenuItem<AppLanguage>(
                        value: lang,
                        child: Text(lang.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  settings.setLanguage(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
