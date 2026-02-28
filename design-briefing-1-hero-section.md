# Design Briefing 1: "Ollie's Day" — Reimagining the Today Tab Hero Section

## Problem Statement

The Today tab currently opens with utilitarian elements: a weather widget, a status line ("Slaapt net 3 min"), then immediately into lists—upcoming items, timeline events. The dog's photo is relegated to a small circle in the top-right corner of the navigation bar.

This creates an experience that feels like opening a task manager rather than checking in on your puppy. The emotional connection—the reason someone downloads a puppy tracker in the first place—is missing from the most important screen in the app.

Users open this app multiple times per day. Each open should feel like a small moment of connection with Ollie, not a glance at a to-do list.

---

## Design Direction

The top of the Today tab should be a **hero moment**—a larger, more immersive section that makes you feel like you're checking in on Ollie. The transition should flow naturally:

1. **Hero:** "How is Ollie right now?" — emotional, visual, present-moment
2. **Schedule:** "What's the plan?" — practical, actionable
3. **Timeline:** "What happened today?" — historical, detailed

The hero should adapt to context: time of day, Ollie's current state (sleeping vs. awake), and whether a recent photo exists.

---

## Concrete Proposals

### Layout Structure

```
┌─────────────────────────────────────┐
│  [Hero Section - ~200pt height]     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │    [Photo / Visual Area]    │    │
│  │                             │    │
│  │    "Ollie is sleeping"      │    │
│  │    💤 Started 45 min ago    │    │
│  │                             │    │
│  │  [Key Stats Row]            │    │
│  │  🚽 2h since pee  🍽 Fed 1h ago  │
│  └─────────────────────────────┘    │
│                                     │
│  [Upcoming Section]                 │
│  ...                                │
│                                     │
│  [Timeline Section]                 │
│  ...                                │
└─────────────────────────────────────┘
```

### Hero Section Components

#### 1. Photo/Visual Area

**When a photo exists for today:**
- Display today's most recent photo as the hero background
- Subtle gradient overlay from bottom to ensure text readability
- Photo fills the hero area (edge-to-edge or with rounded corners)

**When no photo exists:**
- Use the profile photo with a contextual, softly animated background
- Background reflects current state (see State-Aware Backgrounds below)
- Alternatively: abstract, soft gradient that shifts with time of day

**Tap behavior:**
- Tapping the photo area opens the Moments gallery filtered to today
- If no photos today, prompt to add one ("Capture a moment")

#### 2. Current State Display

Prominently show Ollie's current state with:
- **State label:** "Ollie is sleeping" / "Ollie is awake" / "On a walk"
- **Duration:** "Started 45 min ago" / "Awake for 2h 15m"
- **Icon:** Contextual emoji or SF Symbol (moon for sleep, sun for awake, footprints for walk)

The state should be derived from the most recent relevant event:
- Last `slapen` event → sleeping (until `ontwaken` logged)
- Last `ontwaken` event → awake
- Last `uitlaten` event (within reasonable time) → on a walk

#### 3. Key Stats Row

A horizontal row of 2-3 key "right now" metrics:
- **Time since last pee:** "🚽 2h 15m" — tappable to log new potty event
- **Next scheduled item:** "🍽 Lunch in 45m" — tappable to view schedule
- **Weather summary:** "☀️ 18°C, great for walks"

These stats should be glanceable—no labels needed if icons are clear.

#### 4. State-Aware Backgrounds

When Ollie is sleeping:
- Calmer color palette (soft blues, lavender tints from semantic color system)
- Subtle stars or moon iconography (very subtle, not childish)
- Reduced visual "energy"

When Ollie is awake:
- Warmer, brighter palette
- More vibrant gradients
- Higher visual energy

When on a walk:
- Green/teal tints (outdoor palette)
- Could incorporate subtle movement (animated gradient)

---

## Interaction Details

### Scroll Behavior

As the user scrolls down:
1. Hero section compresses (parallax/sticky header behavior)
2. Photo scales down and fades
3. State display remains visible longer, then transitions to a compact bar
4. Compact bar shows: small photo circle + "Sleeping 45m" + key stat

This ensures the emotional moment isn't lost even when viewing the timeline.

### Quick Actions

The hero section could include quick action buttons:
- **Log Potty:** Prominent when time-since-pee is getting long
- **End Nap:** Shows only when sleeping state is active
- **Start Walk:** Quick access to begin walk logging

These should not clutter the visual—perhaps revealed on a secondary tap or as subtle icons.

### Pull-to-Refresh

Pulling down on the Today tab should:
1. Reveal a momentary larger view of Ollie's photo
2. Refresh any synced data
3. Feel delightful, not utilitarian (subtle animation, not a spinner)

---

## Edge Cases

### No Profile Photo Set

- Show a placeholder illustration (friendly, on-brand)
- Prominent CTA: "Add Ollie's photo"
- Background uses time-of-day gradient

### New User (Day 1)

- Hero message: "Welcome to Ollie's first day!"
- Empty state for stats: "Start logging to see stats here"
- Encourage first event logging with prominent button

### Multiple Events Close Together

- State display shows most recent relevant state
- If ambiguous (e.g., walk ended 2 min ago, potty logged 1 min ago), default to "Awake"

### Very Long Sleep (Nighttime)

- Nighttime sleep (10 PM - 6 AM) could show: "Ollie is sleeping through the night 🌙"
- Morning message: "Good morning! Ollie slept 8h 15m"

---

## Dark Mode

- Hero backgrounds shift to darker variants of the state colors
- Photo retains natural colors, gradient overlay adjusts
- Text uses high-contrast variants
- Avoid pure black; use warm dark grays (`#1C1C1E`)

---

## Animation & Polish

### State Transitions

When state changes (e.g., user logs wake-up while viewing):
- Smooth color transition in background (0.5s ease)
- State label fades out/in with crossfade
- Stats update with subtle pulse

### Photo Transitions

- If user adds a photo for today, hero smoothly updates
- Ken Burns-style subtle zoom on static photos (very subtle, optional)

### Micro-interactions

- Tapping stats provides haptic feedback
- State icon could have subtle idle animation (sleeping moon gently pulses)

---

## Technical Considerations

### Performance

- Photo should be pre-loaded/cached
- Background gradients should use Metal/GPU rendering if animated
- State calculation should be efficient (don't recalculate on every frame)

### State Calculation Logic

```
func currentState() -> PuppyState {
    let lastSleep = events.last(where: { $0.type == .slapen })
    let lastWake = events.last(where: { $0.type == .ontwaken })
    let lastWalk = events.last(where: { $0.type == .uitlaten })

    // Determine most recent state-changing event
    // Return .sleeping, .awake, or .onWalk with duration
}
```

### Photo Source Priority

1. Today's most recent photo (from any event)
2. This week's most recent photo
3. Profile photo
4. Placeholder illustration

---

## Open Questions

1. **Collapsibility:** Should users be able to collapse the hero to jump straight to timeline? Or is the hero always present (just compressed on scroll)?

2. **Weather integration depth:** Should weather influence the hero more strongly (rainy day = different vibe) or keep it subtle?

3. **Multiple dogs (future):** If the app ever supports multiple dogs, how does the hero adapt? Tabs? Swipe between?

4. **Photo privacy:** If showing today's photo prominently, ensure user understands photos are local-only (or clearly communicate if/when synced).

5. **Hero height:** 200pt is a starting point. Should it be taller on larger devices? Configurable?

---

## Reference Apps

- **Apple Weather:** Full contextual backgrounds that reflect conditions, time of day
- **Oura Ring:** Daily readiness score as emotional anchor, gradual reveal of details
- **Clue:** Cycle day prominently displayed as the emotional center of the experience
- **Calm:** Time-aware greetings, photo backgrounds, serene state display
- **Duolingo:** Character-forward design where the mascot is the first thing you see

---

## Success Criteria

1. Users report feeling more emotionally connected when opening the app
2. "Checking in on Ollie" becomes the mental model, not "checking the task list"
3. The hero section is immediately understood without explanation
4. State display accuracy is high (users don't see "sleeping" when Ollie is awake)
5. Performance remains smooth (no jank on scroll, no slow loads)
