# Design Briefing 4: Semantic Color System — Beyond Orange

## Problem Statement

The Ollie app currently uses orange as its primary—and nearly only—accent color. Buttons, icons, highlights, filter chips, tab indicators, streaks, and alerts all share the same orange hue. This creates a flat visual hierarchy where nothing stands out because everything stands out.

When a user glances at the Today tab, there's no visual differentiation between:
- A meal that was logged
- A walk that happened
- A sleep session
- An urgent alert about an overdue vaccination

Everything is orange. The eye has no guidance about what matters, what's routine, and what needs attention.

The existing green (potty outside) and red (potty inside/alerts) usage demonstrates the principle works—these semantic colors are immediately understood. But they're isolated cases in an otherwise monochromatic orange world.

---

## Design Direction

Develop a **semantic color system** where color communicates meaning at a glance. The goal is not to create a rainbow explosion, but to establish a restrained, purposeful palette where each color family has a clear domain.

The app should feel like opening a well-organized journal where different aspects of Ollie's life have their own visual identity—without losing cohesion or the warmth of the brand.

---

## Color Palette Proposal

### Primary Categories

| Category | Color Direction | Hex Range (Light Mode) | Used For |
|----------|-----------------|------------------------|----------|
| **Sleep & Rest** | Soft blues, lavender | `#6B7FD7` → `#B8C4E8` | Sleep tracking, nap indicators, bedtime, wake-up |
| **Outdoors & Walks** | Natural greens, teals | `#4A9B7F` → `#A8D5BA` | Walk logging, outdoor potty, places, nature exploration |
| **Meals & Nutrition** | Warm oranges, ambers | `#E8923A` → `#F5C896` | Feeding times, water, portions, food-related items |
| **Health & Medical** | Corals (alerts), soft pinks (care) | `#E85D5D` → `#F5A8A8` | Vaccinations, vet visits, medication, weight, overdue items |
| **Training & Learning** | Purples, indigos | `#7B5FA8` → `#C4B5E0` | Commands, skills, socialization, training sessions |
| **Celebrations & Streaks** | Golds, yellows | `#D4A847` → `#F5E6A8` | Achievements, records, milestones, streak badges |
| **Neutral / System** | Warm grays | `#6B6B6B` → `#F5F5F5` | Containers, backgrounds, secondary text, dividers |

### Brand Color Preservation

The existing orange (`#FF9500` or similar) remains the **primary brand/action color** for:
- Primary buttons (CTA)
- Tab bar selected state
- Floating action button (if applicable)
- Brand moments (splash, onboarding accent)

This ensures brand recognition while freeing content areas to use semantic colors.

---

## Implementation Mapping

### Timeline Events

| Event Type | Current | Proposed |
|------------|---------|----------|
| `slapen` | Orange icon | Blue icon, blue tint on row |
| `ontwaken` | Orange icon | Light blue/lavender icon |
| `eten` | Orange icon | Orange icon (keep) |
| `drinken` | Orange icon | Light amber icon |
| `plassen` (buiten) | Green icon | Green icon (keep) |
| `plassen` (binnen) | Red icon | Red icon (keep) |
| `poepen` (buiten) | Green icon | Green icon (keep) |
| `poepen` (binnen) | Red icon | Red icon (keep) |
| `uitlaten` | Orange icon | Green/teal icon |
| `training` | Orange icon | Purple icon |
| `sociaal` | Orange icon | Purple/indigo icon |
| `milestone` | Orange icon | Gold icon |
| `bench` | Orange icon | Blue icon (rest category) |
| `gewicht` | Orange icon | Coral/pink icon (health) |

### Filter Chips & Categories

The filter chips in various views (timeline filters, places filters) should adopt their category colors:
- "Walks" chip: green background/border
- "Meals" chip: orange background/border
- "Training" chip: purple background/border

This creates immediate visual association between filter and content.

### Insights & Stats

Stats cards should use category colors:
- Sleep analysis card: blue header/accent
- Potty analysis card: green header/accent
- Meal tracking card: orange header/accent
- Training progress: purple header/accent

### Calendar & Schedule

Scheduled items should preview their category:
- Meal reminders: orange indicator
- Walk time: green indicator
- Vet appointment: coral/red indicator
- Training session: purple indicator

---

## Dark Mode Considerations

Each color requires a dark mode variant that:
1. Maintains semantic meaning
2. Reduces saturation slightly to avoid eye strain
3. Ensures WCAG AA contrast ratios (4.5:1 for text, 3:1 for UI elements)

**Proposed dark mode adjustments:**
- Blues become deeper but maintain luminance: `#4A5A9B`
- Greens shift slightly cooler to avoid muddy appearance
- Oranges remain warm but reduce brightness
- All colors tested against dark backgrounds (`#1C1C1E`, `#2C2C2E`)

---

## Accessibility Requirements

### Color Blindness Support

The palette must work for:
- **Deuteranopia/Protanopia (red-green):** The green/red potty distinction needs a secondary indicator (shape, icon, or pattern). Consider: outdoor = checkmark icon, indoor = warning icon, in addition to color.
- **Tritanopia (blue-yellow):** Sleep (blue) vs Celebrations (gold) need distinct iconography.

### Always Pair Color with Shape

Every use of semantic color should include a non-color indicator:
- Icons that differ per category (not just colored versions of the same icon)
- Text labels where space permits
- Patterns or fills as secondary indicators

---

## Rollout Strategy

### Phase 1: Foundation (Non-Breaking)
- Define color tokens in a central `Colors.swift` file
- Create semantic color assets in Asset Catalog
- Audit all current orange usage, categorize by intended meaning

### Phase 2: Timeline First
- Apply semantic colors to timeline event icons
- Update event type → color mapping
- Validate dark mode and accessibility

### Phase 3: Expand to Features
- Stats cards
- Filter chips
- Calendar indicators
- Settings sections

### Phase 4: Polish
- Audit edge cases
- User testing for comprehension
- Adjust based on feedback

---

## Open Questions

1. **Tab bar icons:** Should they adopt category colors when selected (e.g., Places tab = green when active), or remain brand-orange for consistency?

2. **Intensity levels:** Should each category have 3-4 intensity levels (background tint, icon fill, text, border) or keep it simpler with 2 (primary, subtle)?

3. **User customization:** Should power users be able to customize category colors? Adds complexity but could improve accessibility for specific needs.

4. **Transition approach:** Big bang redesign or gradual rollout? Gradual is safer but creates temporary inconsistency.

5. **Training/Socialization split:** Both are currently proposed as purple. Should socialization have its own color (perhaps a warmer purple/magenta) to differentiate from training?

---

## Reference Apps

- **Apple Health:** Category colors per health domain (Activity = green, Sleep = blue, Nutrition = orange)
- **Headspace:** Mood-based color shifts, calming palette
- **Calm:** Soft contextual palettes that shift with content
- **Bear:** Clean theme system with semantic highlighting
- **Oura Ring:** Sleep stages use distinct colors within a cohesive palette

---

## Success Criteria

1. A user can glance at the timeline and immediately distinguish sleep events from walks from meals
2. Filter chips visually match the content they filter
3. No accessibility regressions (all colors pass contrast checks)
4. Dark mode feels cohesive, not like inverted light mode
5. The app still feels like "Ollie" — warm, friendly, not clinical
