import 'package:flutter/material.dart';
import 'theme/theme_controller.dart';
import 'package:provider/provider.dart';

class ThemeSelectorPage extends StatelessWidget {
  const ThemeSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeController>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Izaberi temu")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: controller.reduceMotion,
            onChanged: controller.setReduceMotion,
            title: const Text("Reduce motion"),
            subtitle: const Text("Smanjuje animacije i tranzicije"),
          ),
          SwitchListTile(
            value: controller.highContrast,
            onChanged: controller.setHighContrast,
            title: const Text("High contrast"),
            subtitle: const Text("Pojacava citljivost teksta i UI elemenata"),
          ),
          const SizedBox(height: 8),
          _ThemePreviewCard(
            theme: controller.currentTheme,
            highContrast: controller.highContrast,
          ),
          const SizedBox(height: 8),
          _ThemeCard(
            title: "Sci-Fi",
            selected: controller.currentType == AppThemeType.sciFi,
            onTap: () => controller.setTheme(AppThemeType.sciFi, context),
          ),
          _ThemeCard(
            title: "Fantasy",
            selected: controller.currentType == AppThemeType.fantasy,
            onTap: () => controller.setTheme(AppThemeType.fantasy, context),
          ),
          _ThemeCard(
            title: "Pastel Kids",
            selected: controller.currentType == AppThemeType.pastel,
            onTap: () => controller.setTheme(AppThemeType.pastel, context),
          ),
          _ThemeCard(
            title: "Minimal Light",
            selected: controller.currentType == AppThemeType.minimal,
            onTap: () => controller.setTheme(AppThemeType.minimal, context),
          ),
          _ThemeCard(
            title: "Retro Pixel",
            selected: controller.currentType == AppThemeType.retro,
            onTap: () => controller.setTheme(AppThemeType.retro, context),
          ),
          _ThemeCard(
            title: "Astra Dark",
            selected: controller.currentType == AppThemeType.astra,
            onTap: () => controller.setTheme(AppThemeType.astra, context),
          ),
          const SizedBox(height: 8),
          Text(
            "Reduce motion: ${controller.reduceMotion ? "ukljucen" : "iskljucen"} | "
            "High contrast: ${controller.highContrast ? "ukljucen" : "iskljucen"}",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final ThemeData theme;
  final bool highContrast;

  const _ThemePreviewCard({required this.theme, required this.highContrast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Preview",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: highContrast
                        ? colorScheme.tertiaryContainer
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    highContrast ? "High Contrast" : "Standard",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: highContrast
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Primer naslova i teksta za citljivost.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Primarno",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.secondary),
                  ),
                  child: Text(
                    "Sekundarno",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Aktivno dugme"),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: const Text("Disabled dugme"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Small text preview (WCAG risk zona)",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "12sp primer teksta za proveru citljivosti.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: highContrast
                          ? colorScheme.onSurface
                          : colorScheme.error,
                      fontWeight: highContrast
                          ? FontWeight.w600
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "14sp primer teksta za proveru citljivosti.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!highContrast) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Savet: ukljuci High Contrast za bolju citljivost sitnog teksta.",
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0),
            width: selected ? 2.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withAlpha((0.18 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            title: Text(title),
            trailing: selected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.secondary,
                  )
                : const Icon(Icons.circle_outlined),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
