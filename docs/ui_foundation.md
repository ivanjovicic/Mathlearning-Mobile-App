# MathLearning UI Foundation

## Folder Structure

```text
lib/
  theme/
    app_scale.dart
    app_theme.dart
    app_theme_light.dart
    app_theme_dark.dart
    theme_extensions/
      semantic_colors_extension.dart
      leaderboard_theme_extension.dart
      learning_theme_extension.dart
      status_theme_extension.dart
      theme_context.dart
    tokens/
      app_colors.dart
      app_spacing.dart
      app_typography.dart
      app_radius.dart
      app_shadows.dart
      app_motion.dart
  ui/
    components/
      app_card.dart
      app_button.dart
      app_chip.dart
      app_badge.dart
      app_progress_bar.dart
```

## Usage

```dart
final colors = context.colors;
final spacing = context.spacing;
final radius = context.radius;
final motion = context.motion;

padding: EdgeInsets.all(spacing.m);
borderRadius: BorderRadius.circular(radius.card);
color: colors.cardBackground;
duration: motion.normal;
```

## Validation Checklist

- No hardcoded spacing in new UI code
- No direct semantic colors in widgets
- Prefer `context.colors`, `context.spacing`, `context.radius`, `context.motion`
- Use `AppScale` for fluid sizes and `ConstrainedBox(maxWidth: 720)` for wide layouts
- Respect `MediaQuery.disableAnimations` and text scaling
