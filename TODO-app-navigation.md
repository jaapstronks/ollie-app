# TODO: App Navigation Restructure

## Problem
The web app grew organically into 7 views (home, dag, stats, week, training, fotos, gezondheid) + settings. That's way too many for an iOS tab bar. And 80% of daily usage is just "quick log + check status" — the rest is occasional browsing.

## Principle
Separate **doing** (logging, checking status) from **reviewing** (patterns, training, photos, health). The doing must be instant. The reviewing can be one tap deeper.

## Proposed Structure: 2 Tabs + FAB

### Tab 1: 📋 Vandaag
The daily hub. Everything you need *right now* in a single scrollable view.

**Layout (top to bottom):**
1. **Nav bar:** Date ("Vrijdag 21 feb") + ⚙️ settings gear (pushes to SettingsView)
2. **Weather bar:** Horizontal scroll of upcoming hours (existing WeatherSection)
3. **Weather alert banner:** Smart alert if rain/cold (existing WeatherAlertBanner)
4. **Status cards section:**
   - Potty timer card (time since last, prediction)
   - Poop slot card (ochtend ✅ / middag ○)
   - Sleep progress card (if currently sleeping/napping)
   - Upcoming meal/walk card ("Lunch over 45 min")
5. **Daily digest card:** Compact summary (X buiten, Y binnen, Z maaltijden)
6. **Streak card:** Current outdoor streak 🔥
7. **Timeline:** Today's events in reverse chronological order
   - Each event row is tappable for edit
   - Photo thumbnails inline
   - "Alle events" link at bottom for previous days

**Sticky element:** Quick-log bar pinned to bottom of this tab (above tab bar). Large tap targets for the most common events: 🚽 💩 🍽️ 😴 🚶

**Key merge:** This combines the web app's "home" and "dag" views, which had ~90% overlap. No need for separate views.

**Date navigation:** Swipe left/right to browse previous days (timeline section only), or tap the date header for a date picker. Status cards only show for today.

### Tab 2: 📊 Inzichten
Everything that looks *backward* at patterns and progress.

**Layout (top to bottom):**
1. **Nav bar:** "Inzichten" title
2. **Week grid:** Compact 7-day table (buiten/binnen/eten/wandelingen/slaap/training)
3. **Potty trend chart:** Line chart, outdoor % per day
4. **Pattern cards:** Best time of day, avg gap between potty, sleep analysis
5. **Navigation links section** — cards that push to detail views:

| Card | Destination | Icon |
|------|-------------|------|
| 🎓 Training | TrainingView (full skill tracker) | chevron.right |
| ⚖️ Gezondheid | HealthView (weight + milestones) | chevron.right |
| 📸 Momenten | MomentsGalleryView (photos) | chevron.right |

Each of these is a full view pushed via NavigationStack — not a tab.

### Floating Action Button (FAB)
A prominent ➕ button floating above the tab bar, always visible on both tabs.

**Tap:** Opens the full LogEventSheet (existing)
**Long press:** Haptic + shows radial/list quick menu:
- 🚽 Plassen buiten
- 💩 Poepen buiten
- 🍽️ Eten
- 😴 Slapen / ☀️ Wakker
- 🚶 Uitlaten
- 🎓 Training

These one-tap options create the event immediately with current timestamp and sensible defaults (location: buiten for potty). Brief haptic confirmation, no sheet needed.

**Why FAB instead of center tab:**
- Always visible regardless of scroll position
- Doesn't waste a tab slot
- Standard pattern in tracker apps (Huckleberry, Baby Tracker, etc.)
- Can do both "quick log" (long press) and "full log" (tap)

### Settings
Accessed via ⚙️ gear icon in Vandaag nav bar. Push navigation, not a tab.

Contains:
- Puppy profile (name, breed, birth date)
- Meal schedule configuration
- Walk schedule configuration
- Notification settings
- CloudKit sync status
- About / upgrade

### Night Mode (Future)
When activated (22:00–07:00), replaces the entire UI with a minimal dark overlay. See TODO-night-mode.md. This is a modal presentation over everything, not a tab.

## What This Replaces

| Web App View | iOS Location |
|-------------|-------------|
| Home | → Vandaag tab (merged) |
| Dag | → Vandaag tab (merged) |
| Stats | → Inzichten tab (top section) |
| Week | → Inzichten tab (week grid) |
| Training | → Inzichten → push TrainingView |
| Fotos | → Inzichten → push MomentsGalleryView |
| Gezondheid | → Inzichten → push HealthView |
| Settings | → Gear icon in nav bar |

## Implementation

### Files to Modify
- `ContentView.swift` — replace current TabView with 2-tab + FAB structure
- `Views/TimelineView.swift` — becomes the main "Vandaag" content
- `Views/StatsView.swift` — becomes "Inzichten" with navigation links
- `Views/QuickLogBar.swift` — adapt as sticky bottom bar or FAB menu

### Files to Create
- `Views/FABButton.swift` — floating action button with long-press menu
- `Views/InsightsView.swift` — new Inzichten tab combining stats + navigation
- `Views/TodayView.swift` — new Vandaag tab combining home + day

### Files That Stay (pushed from Inzichten)
- `Views/TrainingView.swift` — already exists or per TODO-training.md
- `Views/HealthView.swift` — per TODO-health.md
- `Views/MomentsGalleryView.swift` — already exists

## Design Notes
- Tab bar: use SF Symbols. `calendar` for Vandaag, `chart.bar` for Inzichten
- FAB: accent color (warm gold), 56pt diameter, subtle shadow, sits 8pt above tab bar
- FAB long-press menu: use the glass card style, appears as a popup above the FAB
- Status cards: keep the existing glass card style, stack vertically
- Quick-log bar on Vandaag: can coexist with FAB (quick-log = common events inline, FAB = full log sheet)
- Or remove the quick-log bar entirely and let the FAB handle everything — cleaner
- Swipe between days: only affects the timeline section, not the status cards
- Keep haptic feedback for logging actions (success haptic on log)

## Reference Apps
- **Huckleberry** (baby tracker): 2 tabs + FAB, very similar use case
- **Apple Fitness:** "Today" hub + browse deeper
- **Apple Health:** Summary + Browse with category navigation
- **Day One:** Single journal view + prominent compose button
