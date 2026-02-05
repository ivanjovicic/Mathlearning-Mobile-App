import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_controller.dart';

class ThemeAccessibilityMiniPreview extends StatelessWidget {
  final String title;
  final bool compact;

  const ThemeAccessibilityMiniPreview({
    super.key,
    this.title = "Brzi pregled pristupacnosti",
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highContrast = context.select<ThemeController, bool>(
      (controller) => controller.highContrast,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: highContrast
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  highContrast ? "Visok kontrast" : "Standardni kontrast",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: highContrast
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "12sp primer za kontrast.",
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: highContrast ? colorScheme.onSurface : colorScheme.error,
              fontWeight: highContrast ? FontWeight.w600 : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "14sp primer za citljivost.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text("Aktivno"),
                ),
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text("Onemoguceno"),
                ),
              ],
            ),
          ],
          if (!highContrast && !compact) ...[
            const SizedBox(height: 6),
            Text(
              "Savet: ukljuci visoki kontrast za sitan tekst.",
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
