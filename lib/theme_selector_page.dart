import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/theme_controller.dart';
import 'widgets/accessibility_settings_section.dart';
import 'widgets/theme_preview_section.dart';
import 'widgets/theme_option_card.dart';
import 'widgets/theme_status_footer.dart';

class ThemeSelectorPage extends StatelessWidget {
  const ThemeSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeController>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Izaberi temu"),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 2,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AccessibilitySettingsSection(
                reduceMotion: controller.reduceMotion,
                highContrast: controller.highContrast,
                onReduceMotionChanged: controller.setReduceMotion,
                onHighContrastChanged: controller.setHighContrast,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ThemePreviewSection(
                theme: controller.currentTheme,
                highContrast: controller.highContrast,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final themes = [
                  AppThemeType.sciFi,
                  AppThemeType.fantasy,
                  AppThemeType.pastel,
                  AppThemeType.minimal,
                  AppThemeType.retro,
                  AppThemeType.astra,
                ];
                final themeTitles = [
                  "Sci-Fi",
                  "Fantasy",
                  "Pastel Kids",
                  "Minimal Light",
                  "Retro Pixel",
                  "Astra Dark",
                ];
                return ThemeOptionCard(
                  title: themeTitles[index],
                  selected: controller.currentType == themes[index],
                  onTap: () => controller.setTheme(themes[index], context),
                );
              },
              childCount: 6,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ThemeStatusFooter(
                reduceMotion: controller.reduceMotion,
                highContrast: controller.highContrast,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
