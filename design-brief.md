# Ollie — Branding Assets Brief for Lovable

**Project:** Ollie — Puppy Journal App
**Platform:** iOS 26 (iPhone, iPad support TBD)
**Design System:** Apple Liquid Glass (iOS 26)
**Date:** February 2026
**Languages:** English (primary), Dutch

---

## About Ollie

Ollie is a puppy journal app that helps new dog owners log daily events: meals, potty breaks, sleep/naps, walks, training sessions, social encounters, and milestones. The app predicts when the next potty break is needed, tracks outdoor streaks, and analyzes patterns over time.

The tone is **warm, playful, and reassuring** — like a best friend who happens to be really organized. The primary audience is first-time dog owners aged 25–45.

---

## Existing Implementation

The app is functional. This brief is for **branding polish**, not from-scratch design.

### Current App Structure

| Tab | Label (EN) | Label (NL) | SF Symbol | Purpose |
|-----|------------|------------|-----------|---------|
| 0 | Journal | Dagboek | `list.bullet` | Today's timeline + event logging |
| 1 | Stats | Stats | `chart.bar` | Potty gaps, sleep analysis, patterns |
| 2 | Moments | Momenten | `photo.on.rectangle` | Photo gallery of logged moments |
| 3 | Settings | Instellingen | `gear` | Profile, meals, notifications, sync |

### Event Types (15 total)

| Type | Label (EN) | SF Symbol | Notes |
|------|------------|-----------|-------|
| `eten` | Eat | `fork.knife` | Meals |
| `drinken` | Drink | `drop.fill` | Water intake |
| `plassen` | Pee | `drop.fill` | Requires inside/outside location |
| `poepen` | Poop | `circle.inset.filled` | Requires inside/outside location |
| `slapen` | Sleep | `moon.zzz.fill` | Start of nap/sleep |
| `ontwaken` | Wake up | `sun.max.fill` | End of nap/sleep |
| `uitlaten` | Walk | `figure.walk` | Outdoor walk |
| `tuin` | Garden | `leaf.fill` | Backyard time |
| `training` | Training | `graduationcap.fill` | Training session |
| `bench` | Crate | `house.fill` | Crate time |
| `sociaal` | Social | `dog.fill` | Meeting other dogs/people |
| `milestone` | Milestone | `star.fill` | Achievement/first-time event |
| `gedrag` | Behavior | `note.text` | Behavioral notes |
| `gewicht` | Weight | `scalemass.fill` | Weight measurement |
| `moment` | Moment | `camera.fill` | Photo moment |

---

## Brand Direction

### Personality

Friendly, modern, slightly playful — but not babyish. Think: the design equivalent of a well-designed children's book for adults. Confident and clean, with warmth.

### Color System (implemented in `OllieColors.swift`)

| Token | Hex | HSL | Usage |
|-------|-----|-----|-------|
| `ollieAccent` | `#E8A855` | `38 75% 62%` | Primary warm gold — main accent |
| `ollieAccentLight` | `#D4A04A` | `35 59% 56%` | Light gold — badges, backgrounds |
| `ollieAccentDark` | `#A36B1D` | `30 72% 37%` | Deep amber — pressed states, poop/crate |
| `ollieSuccess` | `#5BAA6E` | `135 32% 51%` | Green — "buiten" (outside), walks, garden |
| `ollieDanger` | `#D4594E` | `3 63% 57%` | Red — "binnen" (inside), social events |
| `ollieInfo` | `#5BA4B5` | `192 38% 53%` | Teal — drink, pee, weight, stats |
| `ollieSleep` | `#7B8CC2` | `228 36% 61%` | Muted blue — sleep, moments |
| `ollieMuted` | `#6B7280` | `220 9% 46%` | Gray — behavior, secondary text |

### Event Type Color Mapping

| Event Type | Color Token | Rationale |
|------------|-------------|-----------|
| `eten` (Eat) | `ollieAccent` | Warm gold — meals are nurturing |
| `drinken` (Drink) | `ollieInfo` | Teal — water association |
| `plassen` (Pee) | `ollieSuccess` / `ollieDanger` | Green outside, red inside |
| `poepen` (Poop) | `ollieSuccess` / `ollieDanger` | Green outside, red inside |
| `slapen` (Sleep) | `ollieSleep` | Muted blue — calm, restful |
| `ontwaken` (Wake) | `ollieAccent` | Warm gold — new energy |
| `uitlaten` (Walk) | `ollieSuccess` | Green — outdoor activity |
| `tuin` (Garden) | `ollieSuccess` | Green — outdoor activity |
| `training` (Training) | `ollieAccent` | Warm gold — achievement |
| `bench` (Crate) | `ollieAccentDark` | Brown — den/home association |
| `sociaal` (Social) | `ollieDanger` | Red — excitement, energy |
| `milestone` (Milestone) | `ollieAccent` | Warm gold — celebration |
| `gedrag` (Behavior) | `ollieMuted` | Gray — neutral observation |
| `gewicht` (Weight) | `ollieInfo` | Teal — data/measurement |
| `moment` (Moment) | `ollieSleep` | Muted blue — memory, reflection |

### Background Colors

| Context | Light Mode | Dark Mode |
|---------|------------|-----------|
| Background | `hsl(38 60% 97%)` warm cream | `hsl(25 20% 8%)` warm dark |
| Card | `hsl(38 50% 99%)` | `hsl(25 20% 11%)` |
| Border | `hsl(38 30% 88%)` | `hsl(25 15% 18%)` |

**Note:** All colors meet WCAG 4.5:1 contrast requirements. If proposing changes, maintain accessibility.

### Color Philosophy for Liquid Glass

Liquid Glass is inherently neutral and adaptive. The existing warm gold accent (`#E8A855`) works well as the tint color. Ensure any refinements work across both light and dark modes.

### Typography

| Context | Font | Weight | Notes |
|---------|------|--------|-------|
| Body/UI text | SF Pro | Regular (400) | iOS system font |
| Headlines | SF Pro | Bold (700–800) | Or Nunito for warmer feel |
| Logo/wordmark | Nunito | ExtraBold (800) | Rounded, approachable |
| Labels/badges | SF Pro | Semibold (600) | |

**Brand font:** Nunito (Google Fonts) — used in landing page and marketing materials. The iOS app uses SF Pro for native feel, but Nunito can be used for branded elements.

---

## Required Branding Assets

> **Note:** This brief will be given to **Lovable** for AI-assisted design generation. Be specific with hex codes, dimensions, and exact requirements. No ambiguous creative direction.

### 1. App Icon ✅ DESIGNED

iOS 26 Liquid Glass layered icon. 3 discrete layers — system applies specular highlights, refraction & shadows dynamically.

| Variant | Size | Notes |
|---------|------|-------|
| App Icon (master) | 1024×1024 px | Xcode exports at all required scales |
| Dark mode variant | 1024×1024 px | System applies `brightness(0.72)` filter |
| Tinted variant | 1024×1024 px | System applies `grayscale(1) brightness(0.85)` |
| App Store icon | 1024×1024 px | No alpha, no rounded corners (App Store clips it) |

#### Layer Architecture

| Layer | Name | Description |
|-------|------|-------------|
| Layer 0 | Background | Warm amber radial gradient: `#F5BC5A` → `#E09030` (55%) → `#B86818` |
| Layer 1 | Glass Orb | Semi-transparent warm circle — system applies Liquid Glass specular + frosting |
| Layer 2 | Paw Mark | Pure white geometric paw print — 4 oval toe pads + 1 palm pad |

#### Icon Specs
- **No baked-in shadows** — system applies Liquid Glass effects dynamically
- **No text** — reads clearly at 20pt
- **No rounded corners** — iOS applies them (22.4% radius)
- **Paw geometry:** 4 elliptical toe pads in arc + 1 large elliptical palm pad below

#### SVG Source
Available at: `ollie-puppy-s-best-friend/public/ollie-icon-layers.svg`

```svg
<!-- Background gradient -->
<radialGradient id="bg" cx="45%" cy="35%" r="75%">
  <stop offset="0%"   stop-color="#F5BC5A"/>
  <stop offset="55%"  stop-color="#E09030"/>
  <stop offset="100%" stop-color="#B86818"/>
</radialGradient>

<!-- Glass orb gradient -->
<radialGradient id="orb" cx="38%" cy="32%" r="60%">
  <stop offset="0%"   stop-color="#FFECC8" stop-opacity="0.38"/>
  <stop offset="60%"  stop-color="#F5B84A" stop-opacity="0.16"/>
  <stop offset="100%" stop-color="#E8A030" stop-opacity="0.06"/>
</radialGradient>
```

### 2. Wordmark / Logo

For use in launch screen, onboarding, website, and App Store listing.

**Current launch screen uses:** SF Symbol `pawprint.fill` + "Ollie" in SF Pro Bold + "Puppy Journal" subtitle. This works well — only create a custom wordmark if specifically requested.

**If creating custom wordmark:**
- Text: "Ollie"
- Style: Rounded, friendly, approachable (not childish)
- Variants needed: full color, white, black
- Horizontal layout only (no stacked variant needed)
- Minimum legible size: 24pt

### 3. Tab Bar Icons

**Already using SF Symbols.** Custom icons only needed if deviating:

| Tab | Current SF Symbol | Custom? |
|-----|------------------|---------|
| Journal | `list.bullet` | Optional |
| Stats | `chart.bar` | Optional |
| Moments | `photo.on.rectangle` | Optional |
| Settings | `gear` | No — use system |

If creating custom icons:
- 25×25 pt (template rendering mode for tint)
- Match SF Symbols optical weight
- Export as PDF vector

### 4. Onboarding Illustrations

The onboarding is a **5-step wizard** that collects puppy info. Each step could have a small illustration:

| Step | Screen | Illustration idea |
|------|--------|------------------|
| 1 | Name input | Puppy with name tag / collar |
| 2 | Breed selection | Various dog silhouettes |
| 3 | Birth date | Puppy with birthday/calendar motif |
| 4 | Home date | Puppy arriving home / door |
| 5 | Size category | Small to large dog lineup |

**Specs:**
- Style: Soft, semi-flat, warm tones using brand colors
- Size: ~200×200 pt centered above form
- Format: SVG or PDF (for SwiftUI scalability)
- Use `ollieAccent` (`#E8A855`) as the primary illustration color

### 5. Empty State Illustrations

Small spot illustrations for empty data states:

| Context | File | Illustration idea |
|---------|------|------------------|
| Timeline empty | `empty-timeline.svg` | Sleeping puppy / "Nothing yet today" |
| No photos | `empty-moments.svg` | Camera with paw prints |
| Stats insufficient data | `empty-stats.svg` | Chart with "?" or growing puppy |

**Specs:**
- Size: ~120×120 pt
- Style: Match onboarding illustrations
- Format: SVG

### 6. Notification Icons

The app sends push notifications for:

| Notification | SF Symbol (current) | Custom icon? |
|--------------|--------------------|-|
| Potty reminder | `drop.fill` | Optional |
| Meal reminder | `fork.knife` | Optional |
| Nap needed | `moon.zzz.fill` | Optional |
| Walk reminder | `figure.walk` | Optional |

**If creating custom notification icons:**
- Size: 40×40 pt
- Must be visible in both light and dark contexts
- Export as PNG with transparency

### 7. Widget Designs (Future)

Widgets are not yet implemented but are planned. When designing:

| Widget | Content to show |
|--------|----------------|
| Small (2×2) | Time since last potty + prediction |
| Medium (4×2) | Potty status + sleep status side by side |
| Lock Screen circular | Hours until next predicted potty |
| Lock Screen rectangular | "Last pee: Xm ago" |

**Design constraints:**
- Use Liquid Glass material (iOS 26 default)
- Use `ollieAccent` (`#E8A855`) for tint
- Widgets should show data from: potty prediction, sleep status, outdoor streak

### 8. App Store Listing Assets

| Asset | Size | Notes |
|-------|------|-------|
| Screenshots (iPhone 6.9") | 1320×2868 px | Minimum 3, up to 10 |
| Screenshots (iPad 13") | 2064×2752 px | Only if iPad supported |
| App Preview thumbnail | 886×1920 px | Optional video preview |

**Screenshot content (in order):**
1. Timeline view showing today's events with potty prediction card
2. Quick logging — finger tapping the quick-log bar
3. Stats view with outdoor streak and potty gap analysis
4. Moments gallery with photo grid
5. Onboarding showing puppy profile setup

Use device frames. Show actual UI with sample data.

### 9. Launch Screen

**Already implemented.** Current design:
- Background: Linear gradient from `rgb(255, 194, 102)` to `rgb(255, 166, 77)` (warm gold/orange)
- Centered: `pawprint.fill` SF Symbol (80pt, white)
- Text: "Ollie" (SF Pro Bold, white) + "Puppy Journal" (SF Pro Headline, white 90% opacity)

**If replacing:**
- Keep transition seamless to main app background
- Use `ollieAccent` (`#E8A855`) tones
- Center logo at ~120pt

---

## Liquid Glass Compatibility Notes

iOS 26's Liquid Glass affects how branding appears:

1. **Tint is the main brand expression.** The glass tints with your accent color. Ollie uses `#E8A855` (warm gold).
2. **Don't fight the blur.** UI behind glass is intentionally distorted. Keep brand marks above glass layers.
3. **Dark mode matters.** All assets need dark mode variants. OLED displays make this critical.
4. **SF Symbols alignment.** Custom icons should match SF Symbols optical weight and metrics.

---

## Deliverable Format

| Asset type | Format |
|------------|--------|
| App icon | PNG at 1024×1024 (Xcode scales automatically) |
| Tab/notification icons | PDF vector (template rendering mode) |
| Illustrations | SVG |
| Wordmark | SVG + PNG (transparent) |
| Screenshots | PNG |

---

## Reference Apps

For visual tone, reference: **Gentler Streak**, **Bear**, **Streaks**, **Day One**. Clean, opinionated, premium — but Ollie should feel warmer and more playful (puppy energy, not corporate wellness).

---
