# Design Briefing 2: Visual Day Timeline — From List to Narrative

## Problem Statement

The Today tab's timeline is a reverse-chronological list: time, icon, label, optional note. It functions correctly, but it reads like a server log:

```
14:32  🟢 Plassen (buiten)
14:15  ☀️ Ontwaken
12:00  🌙 Slapen
11:45  🍽️ Eten
...
```

For a puppy whose day consists of rhythmic cycles—sleep-wake-potty-eat-play-sleep—there's a natural pattern that this list format obscures. Users can't glance at the timeline and understand "how was Ollie's day?" They have to read and mentally process each line.

The current format also makes it hard to:
- See how long activities lasted (sleep sessions, walks)
- Identify patterns across the day
- Compare today to yesterday at a glance
- Feel the rhythm of the puppy's routine

---

## Design Direction

Create a **visual day representation** that shows the flow of the day at a glance. The timeline should feel less like a log and more like a story—you should be able to "see" Ollie's day without reading every line.

The detailed list view should remain available as a drill-down or alternative, but the default should prioritize **pattern recognition over item counting**.

---

## Primary Proposal: Horizontal Time Bar

### Concept

A horizontal bar representing the day (6 AM to 10 PM, or configurable), filled with colored blocks representing activities. Like a Gantt chart or sleep tracker visualization.

```
6AM                 12PM                 6PM               10PM
├────────────────────┼────────────────────┼─────────────────┤
│░░░░░▓▓▓▓▓▓░░░░░░░░░▓▓▓▓▓▓▓▓░░░░░░░░░▓▓▓▓░░░░░░░░░░░░░░░░│
└────────────────────┴────────────────────┴─────────────────┘

░ = Sleep (blue)
▓ = Awake periods (containing walks, meals, play)
```

### Visual Design

**Block Types:**
- **Sleep blocks:** Blue/purple, solid fill, indicates duration
- **Awake blocks:** Light yellow/cream, contains sub-indicators
- **Walk blocks:** Green overlay or icon marker within awake period
- **Meal blocks:** Orange dot or marker within awake period
- **Potty events:** Small tick marks on the bar (green for outdoor, red for indoor)

**Current time indicator:**
- Vertical line showing "now"
- Area to the right of "now" is slightly faded (future)
- Scheduled items appear as ghost blocks in the future area

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│  Today's Flow                                           │
│  ┌─────────────────────────────────────────────────────┐│
│  │    6     8     10    12    2     4     6     8      ││
│  │    ████░░░░░░████████░░░░░░░░████░░░░░░░░░▒▒▒▒     ││
│  │    sleep │awake│  sleep   │awake│ sleep  │ now      ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  ● 3 walks   ● 4 potty (all outdoor!)   ● 2 meals      │
└─────────────────────────────────────────────────────────┘
```

### Interaction

**Tap on a block:**
- Expands to show details of that period
- Sleep block: start time, end time, duration
- Awake block: list of events during that period (walks, meals, potty, etc.)

**Pinch to zoom:**
- Default view shows full day compressed
- Pinch out to zoom into a section for more detail
- At maximum zoom, transitions to list view for that period

**Swipe left/right:**
- Navigate between days
- Visual comparison: yesterday's pattern appears as a faint ghost behind today

---

## Alternative Proposal: Radial/Clock View

### Concept

A circular visualization where the day is represented as a 24-hour clock face. Activities appear as colored arcs around the circle.

```
           12
          ╱  ╲
        ╱      ╲
      ╱   ████   ╲
     │   █ 💤 █   │
   9 │   ████     │ 3
     │     ████   │
      ╲   ████   ╱
        ╲      ╱
          ╲  ╱
           6
```

### Visual Design

- Inner ring: Sleep (blue arcs)
- Middle ring: Awake/active time
- Outer ring: Event markers (walks, meals, potty)
- Current time: highlighted radial line

### When to Use

The radial view works well for:
- Seeing the sleep/wake rhythm at a glance
- Comparing day/night balance
- Understanding the overall day structure

Less ideal for:
- Detailed timeline reading
- Many overlapping events
- Users unfamiliar with radial time displays

Consider offering as an **alternative view** rather than default.

---

## List View: Enhanced Version

The classic list should remain available and be enhanced:

### Visual Improvements

**Time clustering:**
Instead of every event as equal weight, cluster related events:
```
┌─────────────────────────────────────────────┐
│ Morning (6:00 - 9:30)                        │
│ ├─ 6:15  Woke up                            │
│ ├─ 6:20  Potty outside ✓                    │
│ ├─ 7:00  Breakfast                          │
│ └─ 9:00  Nap started                        │
│                                              │
│ Midday (9:30 - 14:00)                       │
│ ├─ 11:30 Woke up                            │
│ ├─ 11:35 Potty outside ✓                    │
│ ├─ 12:00 Walk (25 min)                      │
│ └─ 13:00 Nap started                        │
└─────────────────────────────────────────────┘
```

**Duration indicators:**
For sleep and walk events, show duration visually:
```
│ 9:00  💤 Nap ─────────── 2h 30m            │
```

**Semantic colors:**
Apply colors from the semantic color system to icons and potentially to row backgrounds (subtle tint).

**Activity grouping:**
Show walks with their associated events inline:
```
│ 12:00  🚶 Walk (25 min)                     │
│        └─ 🟢 Potty: pee + poop              │
│        └─ 🐕 Met: neighbor's dog            │
```

---

## Dual View Toggle

### Implementation

Offer a toggle between visual and list views:

```
┌─────────────────────────────────────────────┐
│ Today                    [═══] [≡]          │
│                          visual  list       │
└─────────────────────────────────────────────┘
```

**Persistence:** Remember user's preference, default to visual.

**Smooth transition:** Animate between views (blocks expand into list items or vice versa).

---

## Day Summary Stats

Both views should include a summary row:

```
┌─────────────────────────────────────────────┐
│ Summary                                      │
│ 💤 12h 30m sleep  │  🚶 3 walks (45 min)    │
│ 🚽 6 potty (5 out) │  🍽️ 3 meals            │
└─────────────────────────────────────────────┘
```

**Tap to expand:** Each summary stat links to filtered view of those events.

---

## Handling Edge Cases

### Day 1 (New User)

- Visual bar shows empty with friendly message
- "Start logging to see Ollie's day take shape"
- First event appears with a celebratory highlight

### Many Events (Busy Day)

- Visual bar handles density gracefully (small tick marks don't overlap)
- List view clusters aggressively
- Summary stats become more valuable

### Future Scheduled Items

- Ghost blocks in visual view (faded, outlined)
- Listed with "(scheduled)" tag in list view
- Tapping scheduled item offers quick actions: start now, reschedule, skip

### Overnight Display

- Night sleep (10 PM - 6 AM) handled specially
- Option 1: 24-hour view with night at the ends
- Option 2: "Night" section at top, "Day" as main view
- Morning view shows: "Last night: Ollie slept 8h 15m 🌙"

### Multi-Day View

For the week/history view:
- Stack of daily bars showing weekly patterns
- Quickly see: Monday was a heavy sleep day, Tuesday had lots of walks

---

## Technical Considerations

### Data Structure for Visual Timeline

Transform events into "activity blocks":
```swift
struct ActivityBlock {
    let type: ActivityType  // .sleep, .awake, .walk
    let startTime: Date
    let endTime: Date?
    let events: [PuppyEvent]  // events contained in this block
    let color: Color
}

func generateDayBlocks(events: [PuppyEvent]) -> [ActivityBlock]
```

### Performance

- Pre-calculate blocks when events change, cache result
- Render visual bar using SwiftUI Canvas or Path for smooth performance
- Virtualize list view for days with many events

### Sleep Session Detection

Logic to pair sleep/wake events into sessions:
```swift
// Find slapen events, match with next ontwaken
// Handle edge cases: missing wake event (still sleeping), multiple sleeps without wake
```

---

## Animation & Polish

### Block Filling Animation

When viewing today, blocks "fill" to current time with a subtle animation:
- Fast-forward through the day's blocks
- Current time indicator pulses gently

### Event Logging Animation

When user logs a new event:
- New block/marker appears with a pop-in animation
- Bar adjusts smoothly if it affects block boundaries

### Day Transition

Swiping between days:
- Horizontal slide of the entire timeline
- Previous/next day bars are pre-rendered for smooth transition

---

## Integration with Hero Section

The visual timeline should feel like a natural extension of the hero:

1. **Hero:** How is Ollie right now? (present moment)
2. **Visual Timeline:** How has Ollie's day flowed? (day pattern)
3. **List View:** What exactly happened? (detailed log)

The visual bar could be a compressed version in the hero that expands as you scroll down.

---

## Open Questions

1. **Default view:** Should visual or list be the default? Consider user testing.

2. **Night handling:** Separate night section or integrated 24-hour view?

3. **Historical comparison:** Show yesterday's pattern as a ghost overlay? Could be powerful but also cluttered.

4. **Radial view value:** Is the clock visualization worth offering as an option, or is it too niche?

5. **Block granularity:** How to handle short events (2-minute potty break) in the visual without them being invisible?

6. **Future items:** How prominently to show scheduled items in the visual? They're predictions, not facts.

---

## Reference Apps

- **Oura Ring:** Sleep stages timeline with clear duration blocks
- **Apple Health:** Activity timeline showing workout blocks
- **Toggl Track:** Time blocks for work tracking, clean visual
- **AutoSleep:** Visual sleep chart with stages and interruptions
- **Bearable:** Health symptom tracking with visual day patterns
- **Gyroscope:** Life tracking with visual time representations

---

## Success Criteria

1. Users can understand "how was today?" in under 3 seconds
2. Pattern recognition improves: users notice "Ollie napped longer than usual today"
3. The visual view becomes the preferred view for most users
4. Detailed list remains accessible for users who prefer it
5. Performance is smooth: no lag on swipe between days
6. Day comparison becomes possible: "this week vs. last week" patterns visible
