# MathLearning — Enterprise Architecture Blueprint

> Generated from a full codebase audit. This document is the source of truth for the UI architecture redesign.

---

## Table of Contents

1. [Current Architecture Audit](#1-current-architecture-audit)
2. [Navigation Architecture](#2-navigation-architecture)
3. [Design System](#3-design-system)
4. [Component Library](#4-component-library)
5. [Dashboard UX](#5-dashboard-ux)
6. [Gamification UI](#6-gamification-ui)
7. [State Architecture](#7-state-architecture)
8. [Performance](#8-performance)
9. [Accessibility](#9-accessibility)

---

## 1. Current Architecture Audit

### What exists today

The codebase contains real, thoughtful work: a design token system (`lib/theme/tokens/`), a scaling engine (`AppScale`), Material 3 throughout, theme caching, a `SchedulerBinding`-based motion auto-tuner, and clean feature module shapes in `features/adaptive_practice/` and `features/learning_map/`.

### Critical issues

#### Router & Navigation

| Issue | Detail |
|---|---|
| Flat `GoRouter` | 23 top-level routes, no `ShellRoute`. `AppScaffold` exists but is **never wired** into the router |
| 3 separate bottom navs | `AppScaffold` (3 items, unused), `HomeScreen` uses `AstraBottomNav` (4 items), `GamifiedHomeScreen` uses `NavigationBar` (4 items) |
| Route detection hack | `AppScaffold` reads `_routeInfo?.value.uri.toString()` and matches with `startsWith` — fragile, false-positive-prone |
| Deprecated GoRouter APIs | Uses `state.location` and `state.queryParams` (removed in GoRouter v10+; should use `state.uri`) |
| No `errorBuilder` | Any bad deep link crashes to a blank screen |
| 4 unreachable screens | `mobile_registration_screen`, `progress_screen`, `user_profile_screen`, `user_search_screen` have no routes |
| Dead prototype route | `/astrax-home` → `AstraHomeScreen` with hardcoded data |

#### Theme System

| Issue | Detail |
|---|---|
| `ThemePreferencesService` is a complete no-op | All `save*` methods return immediately. `loadAllPreferences()` returns `ThemeSettings.initial()` every time. Zero persistence |
| `ValueKey(themeController.currentType)` on `MaterialApp` | Forces **full app rebuild** on theme switch — destroys all widget state, navigation stacks, scroll positions |
| `AppTheme.enhance()` runs after `theme_factory.dart` | Overwrites per-theme fonts (Orbitron, PressStart2P, Marcellus) with SpaceGrotesk+Inter |
| Dual theme files | Root-level `theme_sci_fi.dart` and `themes/scifi_theme.dart` coexist; canonical source unclear |
| `mlx_theme.dart` + `astrax_theme.dart` bypass `theme_factory.dart` | Component theming inconsistent across these themes |
| `AppScale` is static mutable | Not safe for multi-window or testing |

#### Design Tokens — Dual Everything

| Layer | System A | System B | Problem |
|---|---|---|---|
| Spacing | `AppSpacing` (raw consts: `xs=4, s=8, m=16`) | `AppSpacingTokens` (scaled wrappers: `xs, sm, md`) | Different naming. `HomeScreen` uses raw; components use `context.spacing.*` |
| Radius | `AppRadius` in `app_radius.dart` (consts: `small=8, medium=12, card=20`) | `AppRadius` in `radius_tokens.dart` (profile-based: `soft→20, sharp→4`) | Two classes with the same name, different values, different APIs |
| Typography | `AppTypography` (SpaceGrotesk + Inter) | `TypographyConfig` + `buildTextTheme` (per-theme fonts) | `enhance()` overwrites what `theme_factory` built |
| Shadows | `AppShadowTokens` (scaled, 3 methods) | `AppShadows` (static const, unscaled) | No clear canonical source |

#### State & Providers

| Issue | Detail |
|---|---|
| 19 global providers | All alive for the entire app lifecycle, all in one flat `MultiProvider` in `main.dart` |
| Shadow providers | `lib/state/adaptive_provider.dart` shadows `features/adaptive_practice/providers/`. `lib/providers/quiz_provider.dart` is an empty stub |
| Service singletons re-newed | `ApiService()` and `AdaptiveLearningService` are `new`-ed inside multiple `ChangeNotifierProxyProvider.create` lambdas — multiple instances |
| `useGamifiedHome` in ThemeSettings | UI layout concern wrongly placed in theme state |

#### Screen Duplication

| Duplicate | Lines | Notes |
|---|---|---|
| `HomeScreen` | ~800 | Production home |
| `GamifiedHomeScreen` | ~600+ | Gamified variant — duplicates `_bootstrapHome`, `_findRecommendedTopic`, `_resolveQuizTopicId`, `_openTopicPicker`, `_onBottomNavTap`, `_LearningPathBanner` |
| `AstraHomeScreen` | ~400+ | Dead prototype with hardcoded "Good evening, Ivan" |

### Scalability Risks

1. Every new feature adds another flat route + screen file — O(n) routing complexity
2. No component system — every screen is built from scratch, multiplying bug surface
3. Theme never saved — user-facing bug
4. Provider tree has no module boundary — all 19 providers always alive
5. Bottom nav needs to grow but no structural support for nested navigation

---

## 2. Navigation Architecture

### Target: `StatefulShellRoute.indexedStack`

```
GoRouter
│
├── redirect: unauthenticated → /login
│
├── /login                              (no shell — full screen)
├── /onboarding                         (no shell — full screen)
├── /quiz-summary                       (no shell — modal celebration)
├── /reward                             (no shell — modal celebration)
│
└── StatefulShellRoute.indexedStack      (AppShell)
    │
    ├── StatefulShellBranch: /home       (HomeNavigator)
    │   ├── /home                        DashboardScreen
    │   ├── /home/daily-review           DailyReviewScreen
    │   └── /home/heatmap               HeatmapScreen
    │
    ├── StatefulShellBranch: /practice   (PracticeNavigator)
    │   ├── /practice                    PracticeHubScreen
    │   ├── /practice/quiz               QuizScreen
    │   ├── /practice/adaptive           AdaptivePracticeScreen
    │   └── /practice/topic/:topicId     TopicPracticeScreen
    │
    ├── StatefulShellBranch: /learn      (LearnNavigator)
    │   ├── /learn                       LearningMapScreen
    │   ├── /learn/path                  LearningPathScreen
    │   └── /learn/insights              LearningInsightsScreen
    │
    ├── StatefulShellBranch: /ranks      (RanksNavigator)
    │   ├── /ranks                       LeaderboardScreen
    │   └── /ranks/school                SchoolLeaderboardScreen
    │
    └── StatefulShellBranch: /profile    (ProfileNavigator)
        ├── /profile                     ProfileScreen
        ├── /profile/avatar              AvatarCustomizationScreen
        ├── /profile/badges              BadgesScreen
        ├── /profile/settings            SettingsScreen
        ├── /profile/themes              ThemeSelectorPage
        └── /profile/feedback            MyFeedbackScreen
```

### `AppShell` responsibilities

1. **Single bottom nav** — replaces all 3 current implementations. One `NavigationBar` driven by `navigationShell.currentIndex`
2. **Global overlay portal** — `Overlay` entry point for XP popups, achievement toasts, streak milestones. Any child triggers overlays via `OverlayManager` `InheritedWidget`
3. **Offline status banner** — `OfflineStatusWidget` above the nav bar, visible globally

### 5-tab information architecture

| Tab | Icon | Entry | Sub-content |
|---|---|---|---|
| **Home** | House flame | Dashboard | Daily missions, streak, quick-start |
| **Practice** | Lightning bolt | Adaptive practice | Quiz, daily review, difficulty picker |
| **Learn** | Map | Learning map | Skill graph, path view, weekly goal |
| **Ranks** | Trophy | Global leaderboard | School leaderboard, friend view |
| **Profile** | Avatar | Profile | Badges, avatar, settings, insights |

### Nested navigator stacks

`StatefulShellRoute.indexedStack` creates an independent `Navigator` per branch:
- Navigating `/ranks` → `/ranks/school` → switching to `/home` → switching back to `/ranks` restores `/ranks/school` with scroll position
- Back button within a branch pops within that branch; at branch root switches to home tab

### Deep link handling

No `state.extra` for essential navigation — only as optimization cache:

| Current (broken) | Target |
|---|---|
| `/quiz` with `state.extra as int?` | `/practice/topic/42` — topicId in path |
| `/learning-map?userId=x` using `state.queryParams` | `/learn?focus=nodeId` — `state.uri.queryParameters`, userId from `AuthProvider` |
| `/quiz-summary` with `state.extra as QuizSessionStats` | `/quiz-summary?sessionId=abc` — fetches by ID, `extra` as optional cache |
| `/learning-map/practice` with `state.extra as PracticeLaunchPlan` | `/practice/adaptive?planId=xyz` |

### Error route

```dart
GoRouter(
  errorBuilder: (context, state) => ErrorScreen(
    uri: state.uri,
    error: state.error,
  ),
)
```

### Routes to remove

| Route | Reason |
|---|---|
| `/astrax-home` | Dead prototype with hardcoded data |
| `/` redirect | Unnecessary — `initialLocation: '/home'` handles this |

### Migration steps

1. Create `AppShell` widget with `StatefulShellRoute.indexedStack`
2. Move all bottom-nav logic from `HomeScreen`, `GamifiedHomeScreen` into `AppShell`
3. Nest existing screens under branch prefixes
4. Remove `AppScaffold` (unused), `AstraHomeScreen` (dead), and 3 separate bottom-nav implementations
5. Add `errorBuilder`
6. Replace `state.queryParams` → `state.uri.queryParameters`, `state.location` → `state.uri.path`

---

## 3. Design System

### Target: single token layer

Consolidate to **one** implementation per token group. Canonical access is always `context.{group}.{token}`.

### Spacing tokens

Kill raw `AppSpacing` constants. Canonical source: `AppSpacingTokens` (scaled).

| Token | Base | Access |
|---|---|---|
| `xs` | 4 | `context.spacing.xs` |
| `sm` | 8 | `context.spacing.sm` |
| `md` | 12 | `context.spacing.md` |
| `base` | 16 | `context.spacing.base` |
| `lg` | 24 | `context.spacing.lg` |
| `xl` | 32 | `context.spacing.xl` |
| `xxl` | 48 | `context.spacing.xxl` |

Semantic aliases: `screenHPadding`, `screenVPadding`, `cardPadding`, `sectionSpacing`, `itemSpacing`.

All values go through `AppScale.s()` at read time. **No feature code should ever call `AppScale.s()` directly.**

### Radius tokens

Merge the two `AppRadius` classes. Per-theme shape profile (`ThemeShapeProfile`) stays:

| Token | Access |
|---|---|
| `sm` | `context.radius.sm` |
| `md` | `context.radius.md` |
| `lg` | `context.radius.lg` |
| `card` | `context.radius.card` |
| `pill` | `context.radius.pill` (always 999) |

Values set per `ThemeShapeProfile` (soft, rounded, clean, sharp, neon), scaled via `AppScale.radius()`.

### Typography tokens

Kill the dual system. `TypographyConfig` (per-theme fonts from `theme_factory.dart`) survives because it supports theme-specific typefaces. `AppTypography.scaleTheme()` merges into `TypographyConfig` — scaling happens inside `buildTextTheme`, not in a separate `enhance()` step.

Add semantic text style aliases via `ThemeExtension`:

| Alias | Maps to | Use case |
|---|---|---|
| `heading` | `headlineMedium` | Section titles |
| `title` | `titleLarge` | Screen titles |
| `label` | `labelLarge` | Buttons, chips |
| `body` | `bodyMedium` | Content text |
| `caption` | `bodySmall` | Secondary descriptions |
| `scoreDisplay` | `displayMedium` | XP numbers, level display |
| `statNumber` | `headlineSmall` + tabular figures | Leaderboard ranks, streak counts |

### Semantic colors

Extend `AppSemanticColors` (currently 13 fields) with gamification tokens:

| Token | Purpose | SciFi example | Fantasy example |
|---|---|---|---|
| `xpFill` | XP bar gradient start | `#2563EB` | `#10B981` |
| `xpFillEnd` | XP bar gradient end | `#06B6D4` | `#F59E0B` |
| `streakActive` | Active streak flame | `#F97316` | `#DC2626` |
| `streakFrozen` | Frozen streak state | `#93C5FD` | `#E0E7FF` |
| `rankUp` | Leaderboard rank gain | `#16A34A` | `#059669` |
| `rankDown` | Leaderboard rank loss | `#991B1B` @60% | Same |
| `masteryHigh` | Mastered skill node | `#EAB308` | `#D4A017` |
| `masteryLow` | Weak skill node | `#EF4444` @50% | Same |

Each theme defines these in `ThemeData.extensions`.

### Motion tokens

`AppMotion` formalized as semantic roles:

| Role | Duration | Curve | `reduceMotion` fallback |
|---|---|---|---|
| `micro` | 100ms | `easeOut` | `Duration.zero` |
| `feedback` | 160ms | `easeOutCubic` | `Duration.zero` |
| `content` | 260ms | `easeOutCubic` | 100ms fade only |
| `page` | 300ms | `easeInOut` | 100ms fade only |
| `celebration` | 420ms | `easeOutBack` | `Duration.zero` (skip) |

Access: `context.motion.page`, `context.motion.celebration`, etc.

### Shadow tokens

Consolidate to `AppShadowTokens` (scaled). Kill `AppShadows` (unscaled consts). Access: `context.shadows.card`, `context.shadows.elevated`, `context.shadows.focus`.

### AppScale integration rule

```
Token file defines canonical base value
    ↓
AppScale multiplies by device ratio at read time
    ↓
context.spacing.lg / context.radius.card / etc. returns scaled value
    ↓
Component consumes context extension only — never calls AppScale.s() directly
```

Lint convention: `AppScale.s()` is used only inside token wrappers and `lib/ui/components/`.

### `AppTheme.enhance()` removal

`enhance()` runs after `theme_factory.dart`, re-attaching extensions and re-scaling typography — overwriting the factory's work. Remove it. All `ThemeExtension` attachments and typography scaling happen inside `buildTheme()` in `theme_factory.dart` as a single pass. `MaterialApp.builder` no longer modifies the theme.

---

## 4. Component Library

### Hierarchy

```
Atoms — single-purpose, no domain knowledge
│
├── AppButton         variant: primary | secondary | ghost | icon
├── AppBadge          variant: count | status | label
├── AppChip           variant: filter | tag | reward | difficulty
├── AppAvatar         size: xs(24) | sm(32) | md(40) | lg(56) | xl(80)
│                     supports cosmetic layer overlay
├── AppIcon           scaled wrapper for IconData
├── AppProgressBar    linear; semantic label required
├── AppDivider        optional inset label
├── AppSkeletonBox    shimmer placeholder; arbitrary shape/size
└── AppTextField      input with validation state, prefix/suffix slots

Molecules — composed of atoms, still domain-agnostic
│
├── AppCard           surface + padding + header/footer slots
├── AppSurface        colored container with elevation token
├── AppSection        title + optional action slot + child
├── AppListTile       leading + title + subtitle + trailing
├── AppBottomSheet    modal shell with handle + content builder
├── AppDialog         title + content + actions builder
├── AppSnackBar       icon + message + optional action; variant: success|warning|error|info
└── AppEmptyState     icon + title + subtitle + optional CTA

Organisms — domain-aware, compose molecules with business data
│
├── XPProgressBar          gradient fill, level labels, animated value transition
├── StreakIndicator         flame icon + day count + freeze badge
├── BadgeChip              badge icon + name + lock/unlock state
├── LeaderboardTile        rank + avatar + name + XP + delta indicator
├── QuizOptionCard         math content + tap state + correct/wrong reveal
├── RewardCard             cosmetic image + title + unlock CTA
├── AvatarPreview          layered cosmetic rendering (body + equipped items)
├── MasteryRingIndicator   circular progress + percentage + color semantic
├── DailyMissionCard       icon + title + progress bar + XP reward label
├── QuestProgressRow       title + step dots + completion percentage
├── TopicCard              topic name + mastery bar + lock state + quick-play CTA
└── StatisticsCard         stat label + number display + delta badge
```

### Component contracts (universal rules)

**Rule 1 — Tokens only.** No hardcoded `Color`, `double`, `EdgeInsets`, `Duration`, or `BorderRadius` in any component. All values come from `context.spacing.*`, `context.radius.*`, `context.colors.*`, `context.motion.*`. Custom values exposed as constructor parameters with token-based defaults.

**Rule 2 — Touch targets.** Every interactive component wraps its hit area in `ConstrainedBox(constraints: BoxConstraints(minWidth: 48, minHeight: 48))`.

**Rule 3 — Semantics.** Every component that conveys information or accepts interaction carries a `Semantics` widget:
- Progress bars: `Semantics(label: ..., value: '65%')`
- Buttons: `Semantics(button: true, label: ...)`
- Badges/chips: `Semantics(label: ..., hint: 'Unlocked'/'Locked')`
- Tiles: `Semantics(label: concatenated description)`

**Rule 4 — Motion opt-out.** Every component with animation checks `MotionScope.of(context).reduce`. If true, `AnimationController` durations are `Duration.zero` or the animation is skipped entirely.

**Rule 5 — Composition over inheritance.** Organisms are built by composing atoms and molecules via constructor slots, not by extending them.

**Rule 6 — No provider reads.** Atoms and molecules never read from `Provider`. Organisms may read from a provider only if the provider is a required constructor parameter (dependency inversion). The screen passes data down.

### Consolidation targets

| Current duplication | Target |
|---|---|
| `animated_xp_bar`, `astra_xp_bar`, `astrax_xp_bar`, `xp_animation`, `xp_pop_animation` | Single `XPProgressBar` + `XPGainOverlay` |
| `leaderboard_item`, `animated_leaderboard_item` | Single `LeaderboardTile` with `animate` flag |
| `streak_badge_presenter`, `animated_streak_badge`, `daily_streak_badge`, `daily_streak_widget`, `streak_indicator`, `streak_progress_bar` | `StreakIndicator` (display) + `StreakMilestoneOverlay` (celebration) |
| `HomeScreen`, `GamifiedHomeScreen`, `AstraHomeScreen` | Single `DashboardScreen` with configurable sections |

---

## 5. Dashboard UX

### Target: single `DashboardScreen`

Replaces 3 duplicate home screens (~1800+ total lines of duplicated code).

```
DashboardScreen
│
├── DashboardHeader (pinned, not part of scroll)
│   ├── AppAvatar (xs) ──── tappable → /profile
│   ├── StreakIndicator (compact mode)
│   └── XPProgressBar (current level → next)
│
└── CustomScrollView
    │
    ├── SliverToBoxAdapter: ContinueLearningCard
    │   └── Gradient surface with recommended topic + CTA
    │
    ├── SliverToBoxAdapter: AppSection "Daily Missions"
    │   └── SizedBox(height: 120) → ListView.builder(horizontal)
    │       └── DailyMissionCard × N
    │
    ├── SliverToBoxAdapter: AppSection "Quick Practice"
    │   └── 3 × TopicCard (weak topics from SRS engine)
    │       + AppButton "Start Practice" → /practice
    │
    ├── SliverToBoxAdapter: AppSection "Rankings"
    │   ├── StatisticsCard (current rank + delta)
    │   └── LeaderboardTile × 3 (neighbors or top 3)
    │   └── TextButton "See full leaderboard" → /ranks
    │
    ├── SliverToBoxAdapter: AppSection "Achievements"
    │   └── SizedBox(height: 56) → ListView.builder(horizontal)
    │       └── BadgeChip × N (most recent unlocked first)
    │       └── TextButton "All badges" → /profile/badges
    │
    └── SliverToBoxAdapter: AppSection "Learning Progress"
        └── TopicMasteryGrid (skills grouped by subject)
```

### Header UX rationale

The persistent header answers three questions:
1. **Am I on a streak?** → `StreakIndicator`
2. **How close am I to the next level?** → `XPProgressBar`
3. **Who am I?** → `AppAvatar` (identity + profile access)

Pinned so they remain visible while scrolling. Matches Duolingo's persistent streak flame and Khan Academy's persistent mastery indicator.

### Section ordering rationale

| Position | Section | Why |
|---|---|---|
| 1 | Continue Learning | Highest-value action — resume where you left off |
| 2 | Daily Missions | Time-gated content creates urgency |
| 3 | Quick Practice | SRS-driven weak-topic recommendations |
| 4 | Rankings | Social proof drives retention |
| 5 | Achievements | Completion collection, high browse value |
| 6 | Learning Progress | Full mastery map for "review" mode users |

### Eliminating duplication

Delete `GamifiedHomeScreen` and `AstraHomeScreen`. Remove `useGamifiedHome` from `ThemeSettings` (UI layout concern wrongly placed in theme state). Single `DashboardScreen` absorbs the best of both layouts. Future variants use section-level configuration (show/hide sections), not parallel screen implementations.

---

## 6. Gamification UI

### XP gain flow

1. Source widget fires `XPGainEvent` to `OverlayManager` in `AppShell`
2. `OverlayManager` spawns `XPGainOverlay` at source widget's global position (`RenderBox.localToGlobal`)
3. `+N XP` text slides up 40dp, fades out over `context.motion.feedback` (160ms)
4. `XPProgressBar` in `DashboardHeader` animates fill from old → new over `context.motion.content` (260ms)
5. Level-up: `LevelUpOverlay` fires — full-screen overlay with level number, particle burst, dismiss button

**`reduceMotion`**: Steps 1-3 skipped. XP bar jumps instantly. Level-up shows without particles.

### Streak milestones

| Day | Event |
|---|---|
| 3 | Flame color shifts to bright orange |
| 7 | `StreakMilestoneOverlay` — "1 Week!" with confetti |
| 30 | "1 Month!" + unique badge unlock |
| 60, 100, 365 | Same pattern, escalating intensity |

Milestones are ephemeral (shown once, marked seen in local storage). Rendered via `AppShell`'s `OverlayManager`, not as dialogs.

### Badge unlock

1. `ScaleTransition` (0.5 → 1.05 → 1.0) with `Curves.elasticOut` over `context.motion.celebration` (420ms)
2. Glow pulse — `BoxShadow` expansion (2 cycles at 200ms)
3. Haptic: `HapticFeedback.mediumImpact()`

**`reduceMotion`**: Badge appears at full size instantly. No glow. Haptic still fires.

### Cosmetic unlock

1. Silhouette state (solid color fill) for 300ms
2. `ImageFilter.blur` animates σ 8→0 over `context.motion.celebration`
3. Glow border pulse (2 cycles)
4. "Equip" tap → `AvatarPreview` updates via `AnimatedSwitcher`

### Leaderboard rank movement

Staggered `SlideTransition` on load (30ms delay per tile). Rank delta badges:

| Delta | Color | Icon | Label |
|---|---|---|---|
| Positive | `context.colors.rankUp` | ↑ | `+N` |
| Negative | `context.colors.rankDown` | ↓ | `-N` |
| Zero | `context.colors.textSecondary` | `=` | — |
| New entry | `context.colors.xpFill` | ★ | `NEW` |

**`reduceMotion`**: No stagger, all tiles appear simultaneously. Delta badges still show.

---

## 7. State Architecture

### Current: 19 global providers

All alive for entire app lifecycle. `ApiService()` and `AdaptiveLearningService` re-newed in multiple proxy providers.

### Target: 3-tier provider tree

#### Tier 1 — Global (always alive)

| Provider | Reason |
|---|---|
| `ThemeController` | Must be available before any widget renders |
| `AuthProvider` | Gates routing + dependency for many providers |
| `ProgressProvider` | XP/level/streak — used by `DashboardHeader` (always visible) |
| `CoinProvider` | Balance shown in multiple locations |
| `StreakFreezeProvider` | Dependency of `ProgressProvider` |
| `SettingsProvider` | Locale/settings affect entire app |

These stay in root `MultiProvider`.

#### Tier 2 — Shell-scoped (alive while branch is active)

| Provider | Shell branch |
|---|---|
| `QuizProvider` | Practice |
| `AdaptivePracticeProvider` | Practice |
| `LearningMapProvider` | Learn |
| `LearningPathProvider` | Learn |
| `LeaderboardProvider` | Ranks |
| `SchoolLeaderboardProvider` | Ranks |
| `UserProfileProvider` | Profile |
| `AvatarProvider` | Profile |
| `BadgeProvider` | Profile |

Each `StatefulShellBranch` wraps its `Navigator` in a branch-specific `MultiProvider`. Created lazily on first branch visit, persist until shell is destroyed (via `indexedStack`).

#### Tier 3 — Screen-scoped (alive for one screen)

| Provider | Screen |
|---|---|
| `HeatmapProvider` | HeatmapScreen |
| `OnboardingProvider` | OnboardingScreen |

Created as local state in the screen widget, not in any `MultiProvider`.

### Shadow elimination

| Shadow | Action |
|---|---|
| `lib/state/adaptive_provider.dart` | Delete. `features/adaptive_practice/providers/` is canonical |
| `lib/providers/quiz_provider.dart` (empty stub) | Delete. `lib/state/quiz_provider.dart` is canonical |

### Service singleton management

Create shared singletons once in `main.dart` and inject:

```dart
final apiService = ApiService();
final srsService = SrsService.instance;
final learningMapService = LearningMapService(apiService: apiService);
final adaptiveLearningService = AdaptiveLearningService(
  apiService: apiService,
  srsService: srsService,
);
```

Pass to providers via constructor, not via re-newing inside proxy lambdas.

### `MotionScope` InheritedWidget

Placed at `AppShell` level, above all branch navigators:

```dart
reduce = themeController.reduceMotion || MediaQuery.of(context).disableAnimations
```

Widgets access `MotionScope.of(context).reduce` without depending on `ThemeController`. Prevents rebuilds of entire tree when non-motion theme properties change.

---

## 8. Performance

### Widget rebuild containment

**Problem 1**: `key: ValueKey(themeController.currentType)` on `MaterialApp` forces full app rebuild on theme switch.  
**Fix**: Remove the `ValueKey`. `MaterialApp.router` transitions between `ThemeData` objects internally. `GameThemeTransition` handles visual crossfade.

**Problem 2**: `ThemeController.notifyListeners()` triggers on `isSwitching`, `reduceMotion`, and theme type changes. Any `context.watch<ThemeController>()` rebuilds on all.  
**Fix**: Split into `ThemeTypeNotifier` (rare) and `ThemeSettingsNotifier` (motion/contrast toggles). Or: widgets use `context.select<ThemeController, X>()` for specific properties.

**Problem 3**: `HomeScreen` is ~800 lines with a single `build()`. Any state change rebuilds the entire screen.  
**Fix**: Extract each dashboard section into a separate widget. Parent reads providers once, distributes data via constructors.

### Provider lifecycle

Scoped providers (Tier 2/3) reduce active `ChangeNotifier` instances from 19 to 6-10 depending on active branch.

### Animation scope

- `AnimatedBuilder` wrapping only the animated property, not the entire widget
- `RepaintBoundary` around all `CustomPainter` widgets (especially `SkillGraphView` and activity heatmap)
- No `setState` in animation tick callbacks — use `AnimationController` + `AnimatedBuilder` exclusively

### List virtualization

| Screen | Widget | Rule |
|---|---|---|
| LeaderboardScreen | tile list | `ListView.builder` with `itemExtent` (fixed height = faster scroll) |
| BadgesScreen | badge grid | `GridView.builder` + `SliverGridDelegateWithFixedCrossAxisCount` |
| LearningMapScreen | skill nodes | `CustomScrollView` + `SliverList.builder` |
| Dashboard carousels | horizontal lists | `ListView.builder(scrollDirection: horizontal)` + `cacheExtent: 200` |

All lists: `addAutomaticKeepAlives: false`, `addRepaintBoundaries: true`.

### Custom painter repaint control

`SkillGraphView` must implement `shouldRepaint` correctly:

```dart
@override
bool shouldRepaint(SkillGraphPainter old) {
  return old.nodes != nodes || old.edges != edges || old.selectedId != selectedId;
}
```

Use immutable list patterns. Never return `true` unconditionally.

### `AppScale` static state

Convert to `InheritedWidget` that reads `MediaQuery`. Static API remains as convenience that reads from nearest ancestor, but source-of-truth is the widget tree. Makes testing and multi-window safe.

---

## 9. Accessibility

### Screen reader semantics

| Component | Required semantics |
|---|---|
| `XPProgressBar` | `Semantics(label: 'Experience points', value: '$current of $max')` |
| `StreakIndicator` | `Semantics(label: '$days day streak${frozen ? ", frozen" : ""}')` |
| `LeaderboardTile` | `Semantics(label: 'Rank $rank, $name, $xp XP, ${delta description}')` |
| `QuizOptionCard` | `Semantics(button: true, selected: isSelected, enabled: !isAnswered, label: optionText)` |
| `BadgeChip` | `Semantics(label: '$name badge, ${unlocked ? "unlocked" : "locked"}')` |
| `MasteryRingIndicator` | `Semantics(label: '$topic mastery', value: '$percent percent')` |
| `DailyMissionCard` | `Semantics(label: '$title, $progress of $total completed')` |
| `TopicCard` | `Semantics(label: '$topic, mastery $percent percent${locked ? ", locked" : ""}')` |

Rule: if a component contains visual-only information (icons, colors, progress fills), it **must** have a `Semantics` equivalent.

### Touch targets

48×48dp minimum enforced at component layer:
- `AppButton` already enforces `minHeight: 48` — keep
- `AppChip`, `BadgeChip`, `QuizOptionCard` must add `ConstrainedBox(constraints: BoxConstraints(minWidth: 48, minHeight: 48))`
- `LeaderboardTile` row height ≥ 56dp
- `AppAvatar` in tappable contexts: 48×48 hit area even for smaller avatar images

### Contrast

- Audit each theme's `ColorScheme` against WCAG 2.1 AA (4.5:1 body text, 3:1 large text/UI components)
- `outline` at 0.65 alpha and `outlineVariant` at 0.45 alpha risk falling below 3:1 against dark surfaces — pin alpha per-theme
- Gamification colors (`xpFill`, `streakActive`, `rankUp`, `rankDown`) must be tested against their background surface

### Reduce motion

`MotionScope` reads both `ThemeController.reduceMotion` AND `MediaQuery.disableAnimations` (platform-level setting). Currently the app ignores platform setting.

| Category | `reduceMotion: false` | `reduceMotion: true` |
|---|---|---|
| Page transitions | Standard GoRouter transitions | Instant cut |
| XP/streak popups | Slide + fade + particle | Skipped — bar updates instantly |
| Badge/cosmetic reveal | Scale + glow + blur | `AnimatedOpacity` 0→1 over 100ms |
| Leaderboard stagger | 30ms stagger per tile | All tiles appear simultaneously |
| Theme crossfade | `GameThemeTransition.play()` | Instant theme swap |
| Progress bar fills | `Tween<double>` over 260ms | Instant fill |
| Loading skeletons | Shimmer sweep animation | Static grey placeholder |

### Localization

`StateScaffold` hardcoded Serbian (`'Nema podataka'`, `'Pokusaj ponovo'`) must use `context.t.*`. Every user-visible string in the component library must come from `AppLocalizations`.

---

## File-level actions

### Delete

| File | Reason |
|---|---|
| `lib/screens/astrax_home_screen.dart` | Dead prototype |
| `lib/providers/quiz_provider.dart` | Empty stub shadowing real provider |
| `lib/state/adaptive_provider.dart` | Shadow of feature provider |
| `lib/app_scaffold.dart` | Unused (never wired into router) |

### Merge

| From | Into |
|---|---|
| `lib/screens/home_screen.dart` + `lib/screens/home/gamified_home_screen.dart` | New `DashboardScreen` |

### Consolidate

| From (widgets/) | Into |
|---|---|
| `animated_xp_bar`, `astra_xp_bar`, `astrax_xp_bar`, `xp_animation`, `xp_pop_animation` | `XPProgressBar` + `XPGainOverlay` |
| `leaderboard_item`, `animated_leaderboard_item` | `LeaderboardTile` |
| `streak_badge_presenter`, `animated_streak_badge`, `daily_streak_badge`, `daily_streak_widget`, `streak_indicator`, `streak_progress_bar` | `StreakIndicator` + `StreakMilestoneOverlay` |

### Deprecate (move to `lib/theme/legacy/`)

| File | Reason |
|---|---|
| `theme_sci_fi.dart`, `theme_fantasy.dart`, `theme_pastel.dart`, `theme_minimal.dart`, `theme_retro.dart` | Superseded by `themes/` directory |

### Delete duplicate token files (keep scaled versions)

| Delete | Keep |
|---|---|
| `app_spacing.dart` (raw) | `spacing_tokens.dart` |
| `app_radius.dart` (raw) | `radius_tokens.dart` |
| `app_shadows.dart` (raw) | `shadow_tokens.dart` |

### Remove

| Target | Action |
|---|---|
| `AppTheme.enhance()` in `lib/theme/app_theme.dart` | Move extension attachment + scaling into `theme_factory.dart` |
| `ValueKey(themeController.currentType)` in `main.dart` | Remove — causes full app rebuild on theme switch |
| `useGamifiedHome` from `ThemeSettings` | Not a theme concern |
