# MathLearning — Cosmetics Economy Design
**Principal Gamification Designer | Behavioral UX Expert | Backend Systems Architect**  
_Version 1.0 — March 2026_

---

## 1. Gamification System Audit

### Existing Mechanics

| Mechanic | Motivation Strength | Engagement Frequency | Visual Reward Visibility | Habit Reinforcement |
|---|---|---|---|---|
| XP Progression | High (clear growth) | Every session | Medium (XP bar) | Strong |
| Daily Streaks | Very High (loss aversion) | Daily | Medium (flame icon) | Very Strong |
| Badges / Achievements | Medium (milestone rewards) | Sporadic | Low (badge list) | Weak |
| Global Leaderboard | High (competition) | Daily | High (ranked list) | Medium |
| School Competitions | High (team identity) | Weekly | Medium | Medium |

### Weaknesses Identified

**Reward Saturation**
- XP alone becomes meaningless after early levels; numbers increase but mean nothing visually.
- Badges pile up with no emotional resonance — the badge list is a data dump, not a trophy wall.

**Lack of Visual Rewards**
- Nothing changes visually as a player progresses. A Level 1 and a Level 50 player look identical.
- The leaderboard shows names — no visual identity differentiation.

**Poor Progression Feedback**
- No "near-win" mechanic that pulls players back when they're close to something.
- No seasonal scarcity — everything is always available, removing urgency.

**Limited Long-Term Motivation**
- After unlocking all badges, there is nothing left to pursue cosmetically.
- No collection system — no "I need just 2 more items to complete this set."
- Social comparison is limited to numbers, not visual identity.

### Where Cosmetics Can Help

| System | Cosmetic Opportunity |
|---|---|
| XP Milestones | Unlock cosmetics at key levels (5, 10, 20, 50) |
| Daily Streaks | Exclusive streak-based avatar frames and emojis |
| Badges | Each badge unlocks a corresponding badge pin cosmetic |
| Leaderboard | Top 3 / Top 10 rank frames visible next to username |
| School Competitions | School-themed seasonal cosmetics |

---

## 2. Player Motivation Model

The cosmetic system is designed using the **SINEM Framework**:

| Driver | Implementation |
|---|---|
| **S**tatus Signaling | Rare frames and badges are visible on leaderboards |
| **I**dentity Expression | Skin tones, hair, clothing let players "be themselves" |
| **N**ear-Win Tension | Progress bars showing "3 items to complete this set" |
| **E**ndowment Effect | Once players customize their avatar, they want to keep it |
| **M**astery Progression | Cosmetics unlock at visible XP thresholds (not random) |

### Additional Psychological Levers

- **Sunk Cost / Investment**: Players who spend time customizing feel more ownership.
- **Social Proof**: Seeing other players' cool avatars on the leaderboard motivates unlocking.
- **Scarcity Urgency**: Seasonal items with countdown timers create FOMO-driven daily login.
- **Collection Completion**: Showing a "4/5 unlocked in this set" is more compelling than just owning items.
- **Variable Ratio Reinforcement**: Rare drops in loot-box style reward tracks keep engagement high.

---

## 3. Cosmetic Categories

### Category Catalog

| Category | Description | Example Items |
|---|---|---|
| `avatar_skin` | Base avatar skin/color | Neutral, Golden, Galaxy, Neon |
| `hair_style` | Hair shape and color | Curly Brown, Straight Blonde, Afro, Mohawk |
| `clothing` | Shirt/jacket worn by avatar | School Uniform, Sci-Fi Suit, Champion Hoodie |
| `accessory` | Worn item (hat, glasses) | Graduation Cap, VR Goggles, Math Crown |
| `emoji_reaction` | Reactions used in quizzes | 🔥 Streak Flame, ⚡ Speed, 🧠 Genius |
| `avatar_frame` | Border around avatar photo/icon | Gold Laurel, Neon Ring, Seasonal Snowflake |
| `profile_background` | Background of profile card | Galaxy, Forest, Chalkboard, Circuit Board |
| `profile_badge` | Mini icons on the profile page | Top 10, Streak Master, Olympiad Winner |
| `reaction_sticker` | Stickers sent during school comp | 🎉 Nice, 💪 Keep Going, 🤯 Mindblown |
| `animated_effect` | Animation overlay (future) | XP Burst, Rainbow Trail, Confetti |

### Cosmetic Item Metadata

```dart
class CosmeticItem {
  final String id;
  final String name;
  final CosmeticCategory category;
  final CosmeticRarity rarity;
  final String unlockCondition;   // Human-readable description
  final String assetPath;         // Icon/image reference
  final String? seasonId;         // null = permanent
  final bool isLimited;
  final DateTime createdAt;
}
```

### Visual Rarity Progression

| Rarity | Color | Visual Treatment |
|---|---|---|
| Common | Grey | Flat color, no border |
| Rare | Blue | Subtle glow border |
| Epic | Purple | Animated shimmer |
| Legendary | Gold/Orange | Particle effect on equip |
| Mythic | Rainbow/Gradient | Full animation, season-exclusive |

---

## 4. Cosmetic Rarity System

### Rarity Tiers

| Tier | Color Code | Drop % | Visual Complexity | Seasonal Exclusive | Prestige |
|---|---|---|---|---|---|
| Common | `#9E9E9E` | 60% | Flat icon | No | Low |
| Rare | `#2196F3` | 25% | Glow border | No | Medium |
| Epic | `#9C27B0` | 10% | Shimmer animation | Possible | High |
| Legendary | `#FF9800` | 4% | Particle effects | Possible | Very High |
| Mythic | `Rainbow` | 1% | Full animated | **Yes — Season only** | Prestige |

### Unlock Distribution by Source

| Source | Distribution |
|---|---|
| XP Level Ups | Weighted: 60% Common, 30% Rare, 10% Epic |
| Season Track Levels | Curated: designer-selected items at each tier |
| Leaderboard Top Rewards | Rare → Legendary by rank |
| Achievement Unlock | Fixed: linked to badge rarity |
| Event / Competition | Curated: Epic/Legendary, time-limited |

---

## 5. Unlock Mechanics

### Primary Pathways

| Pathway | Trigger | Example Reward |
|---|---|---|
| Level Progression | Reach level N | Level 5 → "Study Hat" (Rare) |
| XP Milestone | Earn X total XP | 1000 XP → "Scholar Frame" |
| Badge Earned | Complete achievement | "Streak Master" badge → Flame emoji pack |
| Leaderboard Rank | End-of-week Top 3/10/50 | Top 3 → Gold Laurel Frame (Legendary) |
| School Competition | Win/place in school vs school | School Champion Hoodie |
| Daily Streak | Maintain N-day streak | 7 days → Streak emoji, 30 days → Flame Frame |
| Daily Missions | Complete daily goal | Common cosmetic ticket |
| Season Track | Reach season level L | Curated reward at each tier |
| Special Events | Participate in event | Event-exclusive cosmetic |

### Scaling Rewards by Progress

```
Early Game  (L1-10):   Common items every 1-2 levels — build the collection fast
Mid Game    (L11-30):  Rare items every 3-5 levels — increase investment
Late Game   (L31-50):  Epic items every 5-10 levels — prestige milestones
Endgame     (L50+):    Legendary+ items for major achievements only
```

---

## 6. Cosmetic Collection System

### Collection Mechanic

Each category groups items into **Sets** (themed collections):  

```
Set: "Math Olympiad 2026"
  ├── 🟠 Gold Laurel Frame         [Legendary]  ✓ Unlocked
  ├── 🔵 Champion Shirt            [Rare]        ✓ Unlocked  
  ├── 🟣 Pi Symbol Accessory       [Epic]        🔒 Locked
  └── 🌈 Olympiad Mythic Skin      [Mythic]      🔒 Locked
Progress: 2/4 (50%)
```

### UI Concepts

- **Gallery tab** per category (Avatar, Frames, Backgrounds…)
- **Set completion progress bar** at the top of each set group
- **Locked items show silhouette + unlock hint** (not hidden entirely — the "near win" effect)
- **Completion reward** when a set is fully unlocked (bonus XP or a bonus cosmetic)

---

## 7. User Inventory System

### Data Model

```dart
class UserCosmetic {
  final String id;
  final String userId;
  final String itemId;
  final DateTime unlockedAt;
  final String sourceType;   // 'level_up' | 'achievement' | 'leaderboard' | 'event' | 'season'
  final String? sourceEvent; // e.g. 'season_winter_2026', 'event_olympiad_2026'
}
```

### Backend: `user_cosmetics` Table

```sql
CREATE TABLE user_cosmetics (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id),
  item_id       VARCHAR(64) NOT NULL REFERENCES cosmetic_items(id),
  unlocked_at   TIMESTAMP NOT NULL DEFAULT now(),
  source_type   VARCHAR(32) NOT NULL,
  source_event  VARCHAR(64),
  INDEX idx_user_cosmetics_user (user_id),
  INDEX idx_user_cosmetics_item (item_id),
  UNIQUE (user_id, item_id)
);
```

### Inventory Rules

- **Seasonal items** remain in inventory permanently after unlock.
- **Limited items** cannot be re-unlocked if missed.
- **Duplicate protection**: unique constraint per (user_id, item_id).
- **Export/Import**: inventory is portable across devices via server sync.

---

## 8. Avatar Configuration System

### Data Model

```dart
class UserAvatar {
  final String userId;
  final String? skinId;
  final String? hairId;
  final String? clothingId;
  final String? accessoryId;
  final String? emojiId;
  final String? frameId;
  final String? backgroundId;
  final DateTime updatedAt;
}
```

### Backend: `user_avatar` Table

```sql
CREATE TABLE user_avatar (
  user_id       UUID PRIMARY KEY REFERENCES users(id),
  skin_id       VARCHAR(64) REFERENCES cosmetic_items(id),
  hair_id       VARCHAR(64) REFERENCES cosmetic_items(id),
  clothing_id   VARCHAR(64) REFERENCES cosmetic_items(id),
  accessory_id  VARCHAR(64) REFERENCES cosmetic_items(id),
  emoji_id      VARCHAR(64) REFERENCES cosmetic_items(id),
  frame_id      VARCHAR(64) REFERENCES cosmetic_items(id),
  background_id VARCHAR(64) REFERENCES cosmetic_items(id),
  updated_at    TIMESTAMP NOT NULL DEFAULT now()
);
```

### UI Flow

1. Open **Avatar Customization Screen** from Profile.
2. Preview avatar live in real-time as slots are selected.
3. Category tabs: Skin → Hair → Clothing → Accessory → Frame → Background.
4. Each tab shows the user's owned items; locked items shown as greyed silhouettes.
5. Tap **Apply** → saves config via `POST /api/avatar/update`.
6. Avatar immediately visible in profile, leaderboard, etc.

---

## 9. Seasonal Cosmetic System

### Seasons

| Season | Duration | Theme | Exclusive Cosmetics |
|---|---|---|---|
| Math Olympiad | 4 weeks | Trophies, medals, scholar robes | Gold Laurel Frame, Champion Shirt |
| Back-to-School | 3 weeks | Backpacks, pencils, notebooks | Pencil Accessory, Notebook Background |
| Halloween | 2 weeks | Spooky math | Ghost Frame, Jack-o-Lantern Skin |
| Winter / New Year | 3 weeks | Snowflakes, stars | Snowflake Frame, Winter Hoodie |
| Summer Break | 4 weeks | Beach, sun, formula boards | Sunglasses Accessory, Beach Background |

### Rotation Rules

1. Season announces 1 week before start with preview of cosmetics.
2. Season track opens — players earn seasonal XP through normal quizzes.
3. At season end, all limited cosmetics are locked forever.
4. Season-winner reward: extra exclusive Mythic cosmetic for top completers.

---

## 10. Reward Track (Battle Pass Style)

### Season Track Structure

```
Tier  1  ──  Streak Emoji Pack         [Common]
Tier  3  ──  Scholar Background        [Common]
Tier  5  ──  Season Shirt              [Rare]
Tier  8  ──  Season Frame              [Rare]
Tier 10  ──  Epic Avatar Skin          [Epic]
Tier 15  ──  School Crest Accessory    [Epic]
Tier 20  ──  Season Legendary Frame    [Legendary]
Tier 25  ──  Full Season Mythic Skin   [Mythic] ← Season Capstone
```

### Progression Pacing

- 1 season tier ≈ 200 seasonal XP.
- Average daily session = ~80 seasonal XP → ~2.5 tiers/week.
- Full track (25 tiers) completes in ~10 weeks for dedicated players.
- Casual players (3 days/week) complete 15 tiers → Epic item before season end.
- "Hard but achievable" design: Mythic requires near-daily play.

---

## 11. Social Visibility

### Where Avatars Are Displayed

| Context | What Shows |
|---|---|
| Leaderboard row | Avatar frame + skin + hair |
| School competition | Full avatar + school badge |
| Profile screen | Full avatar + background + badges |
| Friend list | Frame + skin thumbnail |
| Achievement feed | Avatar + achievement badge |
| Quiz answer reactions | Emoji reaction from equipped emoji pack |

### Status Motivation

Rare frames and Legendary skins act as **social proof** of effort. When a student sees a classmate's Gold Laurel frame, they are motivated to earn it. The leaderboard becomes not just a ranking list but a **visual gallery of achievement**.

---

## 12. Economy Balance

### Balance Goals

| Goal | Mechanism |
|---|---|
| No reward inflation | Fixed unlock costs, not random |
| Prestige scarcity | Legendary/Mythic have hard unlock gates |
| No early overload | Common unlocked early, rares gated |
| Sustained daily engagement | Season track + daily streak cosmetics |

### Long-Term Balance Strategy

- **Seasons cycle** every 4-8 weeks, constantly refreshing the catalog with new items.
- **Legacy items** remain in catalog but are never re-issued in seasons (historical prestige).
- **New categories** introduced gradually (animated effects in Year 2).
- **Community vote**: Once per season, players vote for a bonus community cosmetic.

---

## 13. Anti-Abuse Design

### Safeguards

| Threat | Mitigation |
|---|---|
| XP farming (bots) | Rate limit answer submissions (max 3/min), behavioral analysis |
| Duplicate unlocks | DB unique constraint + server-side validation |
| Leaderboard manipulation | Minimum session count threshold for rank rewards |
| Event farming (multi-accounts) | Device fingerprinting + account age gate |
| Season skip (clock manipulation) | Server-side timestamp validation |

### Unlock Validation Flow

```
Client: "I reached Level 5"
Server: Verify XP in DB ≥ level_5_threshold
Server: Check user_cosmetics — item not already owned
Server: Insert into user_cosmetics
Server: Return confirmation + item data
```

---

## 14. Backend Data Architecture

### Core Tables

```sql
-- Cosmetic catalog
CREATE TABLE cosmetic_items (
  id                VARCHAR(64) PRIMARY KEY,
  name              VARCHAR(128) NOT NULL,
  category          VARCHAR(32) NOT NULL,
  rarity            VARCHAR(16) NOT NULL,
  unlock_condition  TEXT,
  asset_path        VARCHAR(256) NOT NULL,
  season_id         VARCHAR(64),
  is_limited        BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMP NOT NULL DEFAULT now(),
  INDEX idx_cosmetic_category (category),
  INDEX idx_cosmetic_season (season_id)
);

-- User inventory
CREATE TABLE user_cosmetics (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id),
  item_id       VARCHAR(64) NOT NULL REFERENCES cosmetic_items(id),
  unlocked_at   TIMESTAMP NOT NULL DEFAULT now(),
  source_type   VARCHAR(32) NOT NULL,
  source_event  VARCHAR(64),
  UNIQUE (user_id, item_id),
  INDEX idx_user_cosmetics_user (user_id)
);

-- Equipped avatar configuration
CREATE TABLE user_avatar (
  user_id       UUID PRIMARY KEY REFERENCES users(id),
  skin_id       VARCHAR(64),
  hair_id       VARCHAR(64),
  clothing_id   VARCHAR(64),
  accessory_id  VARCHAR(64),
  emoji_id      VARCHAR(64),
  frame_id      VARCHAR(64),
  background_id VARCHAR(64),
  updated_at    TIMESTAMP NOT NULL DEFAULT now()
);

-- Seasons
CREATE TABLE cosmetic_seasons (
  id          VARCHAR(64) PRIMARY KEY,
  name        VARCHAR(128) NOT NULL,
  start_date  TIMESTAMP NOT NULL,
  end_date    TIMESTAMP NOT NULL,
  theme       TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT false
);

-- Season reward track
CREATE TABLE season_rewards (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  season_id  VARCHAR(64) NOT NULL REFERENCES cosmetic_seasons(id),
  tier       INTEGER NOT NULL,
  item_id    VARCHAR(64) NOT NULL REFERENCES cosmetic_items(id),
  xp_needed  INTEGER NOT NULL
);

-- Events
CREATE TABLE cosmetic_events (
  id          VARCHAR(64) PRIMARY KEY,
  name        VARCHAR(128) NOT NULL,
  start_date  TIMESTAMP NOT NULL,
  end_date    TIMESTAMP NOT NULL,
  eligibility_rules JSONB
);
```

---

## 15. API Design

### Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/cosmetics/catalog` | Full cosmetic catalog (cached, 1hr TTL) |
| GET | `/api/cosmetics/inventory` | Current user's unlocked items |
| POST | `/api/cosmetics/unlock/{itemId}` | Unlock item (server validates eligibility) |
| GET | `/api/avatar/config` | Current user's equipped avatar config |
| POST | `/api/avatar/update` | Update avatar slot configuration |
| GET | `/api/seasons/current` | Active season data + reward track |
| GET | `/api/seasons/rewards` | Season track with user progress |
| GET | `/api/cosmetics/sets` | Collection sets with completion progress |

### Expected Response: GET /api/cosmetics/catalog

```json
{
  "items": [
    {
      "id": "frame_gold_laurel",
      "name": "Gold Laurel Frame",
      "category": "avatar_frame",
      "rarity": "legendary",
      "unlock_condition": "Reach Top 3 on the weekly leaderboard",
      "asset_path": "assets/cosmetics/frames/gold_laurel.png",
      "season_id": "season_olympiad_2026",
      "is_limited": true,
      "created_at": "2026-01-01T00:00:00Z"
    }
  ],
  "total": 150,
  "cached_at": "2026-03-08T10:00:00Z"
}
```

### Caching Strategy

| Endpoint | Cache Strategy |
|---|---|
| `/catalog` | CDN cache, 1 hour TTL; invalidate on item publish |
| `/inventory` | User-scoped, 5 min TTL; invalidate on unlock |
| `/avatar/config` | User-scoped, 5 min TTL; invalidate on update |
| `/seasons/current` | Shared CDN, 15 min TTL |

---

## 16. Analytics & Telemetry

### Key Metrics

| Metric | Goal |
|---|---|
| `cosmetic_unlock_rate` | > 2 unlocks/user/week |
| `avatar_customization_rate` | > 60% of DAU have customized avatar |
| `season_completion_rate` | > 30% complete 15+ tiers |
| `cosmetic_display_views` | Leaderboard impressions of rare+ cosmetics |
| `d7_retention_delta` | Measure retention improvement post-cosmetics launch |
| `daily_login_streak_correlation` | Does cosmetic unlock extend streak maintenance? |
| `inventory_open_rate` | % of users who browse cosmetics weekly |

### Balancing Feedback Loop

1. Monthly review: Are Epic/Legendary unlock rates too high/low?
2. If < 5% of players have any Epic → lower XP gates or add more unlock paths.
3. If > 40% of players have Legendary in Week 1 → season is too easy, tighten gates.
4. A/B test season track pacing against retention metrics.

---

## 17. Future Expansion

The system is designed for extension:

| Feature | Timeline | Notes |
|---|---|---|
| Cosmetic shop (coins) | Year 2 | Pay with in-game coins earned via learning |
| Season passes (premium) | Year 2 | Free track + paid premium track (never pay-to-win) |
| Limited event drops | Year 1 | Already in architecture |
| School cosmetic competitions | Year 2 | School-branded cosmetics for winning schools |
| Avatar animations | Year 2 | AnimatedEffect category already in schema |
| Reaction emotes in quizzes | Year 1 Phase 5 | Already scaffolded in emoji_reaction category |
| Trading / gifting | Year 3 | Requires separate economy design |

---

## 18. Implementation Roadmap

### Phase 1 — Avatar Customization System (Current Sprint)
- Define `CosmeticItem`, `UserAvatar`, `UserCosmetic` models
- Create static cosmetic catalog (100 base items, no backend required)
- Build `AvatarWidget` (renders equipped avatar)
- Build `AvatarCustomizationScreen` with category tabs
- Persist avatar config locally (SharedPreferences)
- Wire avatar into Profile screen and Leaderboard

### Phase 2 — Inventory + Unlock Rewards
- `UserCosmetic` inventory stored locally + server sync
- Unlock events: level-up, badge earned, streak milestone
- "Collection" view with locked silhouettes
- Unlock animation popup

### Phase 3 — Season System
- Season model + backend endpoint
- Seasonal cosmetics tied to current season
- Countdown timer for season end

### Phase 4 — Reward Track
- Season track UI (linear progress, tiers, rewards)
- Seasonal XP accumulation separate from main XP
- Track completion reward (Mythic cosmetic)

### Phase 5 — Advanced Social Features
- Avatar visible in leaderboard rows
- Avatar visible in school competition tables
- Reaction emotes during quizzes
- Achievement feed with avatars

---

## Final Summary

The MathLearning cosmetics economy is built on five pillars:

1. **Expression** — players can represent themselves visually.
2. **Progression** — cosmetics unlock as measurable rewards of learning effort.
3. **Prestige** — rare cosmetics are visible and signal achievement to peers.
4. **Engagement** — seasons and events create urgency and fresh content continuously.
5. **Safety** — purely visual, no gameplay advantage, educational environment-safe.

This system is designed to increase DAU, d7/d30 retention, and daily streak maintenance by transforming abstract XP numbers into visible identity markers that students are proud to display.
