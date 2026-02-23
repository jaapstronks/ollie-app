# Briefing: Socialization v2 — Today Integration

## Current State (v1)

Socialization tracking lives in the **Plan** tab as a standalone checklist:
- User taps item → logs exposure (distance + reaction) → progress updates
- Walk suggestions card appears in Today view
- Exposures are stored separately from PuppyEvents
- No connection between timeline events and socialization progress

This works well for **intentional** socialization practice, but misses **spontaneous** encounters.

## The Integration Question

Should exposures logged from Plan also appear in the timeline? And vice versa — should social events in the timeline link to socialization items?

### Why This Is Tricky

**Scenario 1: Walk with multiple encounters**
User goes for a walk, sees a cyclist, passes a dog, observes a child playing.
- Current: Log walk event (uitlaten) → done
- With integration: How do we capture the 3 exposures?
  - Sub-events like potty during walk?
  - Separate events cluttering timeline?
  - Post-walk summary screen?

**Scenario 2: Indoor exposure**
User runs vacuum cleaner while puppy watches from distance.
- Not a walk, not really a "social" event
- But it IS a socialization exposure
- Where does this belong in the timeline?

**Scenario 3: Quick encounter**
Passed a motorcycle on a 2-minute errand walk.
- Too minor to log as a full event
- But valuable for socialization tracking
- User might forget if not logged immediately

## Design Options

### Option A: Keep Them Separate (Current)

**Socialization = Plan tab only**
- Exposures tracked for progress, not for timeline
- "Walk suggestions" card prompts awareness
- User logs exposures after returning home

**Pros:**
- Clean separation of concerns
- Timeline stays focused on major events
- No data model changes needed

**Cons:**
- Misses the "spontaneous log" use case
- No record of WHEN exposures happened in context of the day
- Duplicate info if user also logs social event

---

### Option B: Exposures as Sub-Events of Walks

Like potty events during walks, exposures could be "child events" of a walk.

```
Walk (15 min, Park)
  └── 🚴 Cyclist — near, neutral
  └── 🐕 Dog — far, positive
  └── 💧 Pee — outside
```

**Pros:**
- Logical grouping — most exposures happen during walks
- Doesn't clutter main timeline
- Walk detail view shows the full story

**Cons:**
- What about non-walk exposures? (vacuum, doorbell, handling)
- Requires "expand walk" UI in timeline
- Complex data model (walk → exposures → reactions)

---

### Option C: Unified "Social" Event with Optional Socialization Link

Extend existing `sociaal` event type:

```swift
// When logging social event, optionally link to checklist
PuppyEvent.social(
    who: "Cyclist on path",
    note: "Stayed calm, got treat",
    socializationItemId: "fietser",      // NEW
    exposureDistance: .near,              // NEW
    exposureReaction: .neutraal           // NEW
)
```

**Pros:**
- Natural flow — log event, optionally enrich it
- Single source of truth (PuppyEvent)
- Existing timeline UI works

**Cons:**
- "Social" event type overloaded (meeting dogs vs seeing cyclists)
- What about non-social exposures? (sounds, surfaces, handling)
- Reaction picker adds friction to quick logging

---

### Option D: New "Exposure" Event Type

Create dedicated event type for socialization:

```swift
EventType.exposure  // New type alongside .sociaal
```

Timeline shows:
```
14:32  🎯 Exposure — Cyclist (near, neutral)
14:28  💧 Pee — outside
14:15  🚶 Walk started
```

**Pros:**
- Clear intent — this is specifically for socialization
- Can be standalone or during walk
- Full logging flexibility

**Cons:**
- Clutters timeline with many small events
- Another event type to explain to users
- Overlaps with .sociaal conceptually

---

### Option E: Quick-Log Mode During Active Walk

When walk is in progress, show "exposure buttons" in quick-log bar:

```
[Active Walk: 12 min]
Quick log: 🚴 👥 🐕 🔊 📦
```

Tap → mini sheet with distance + reaction → logged as walk sub-event.

**Pros:**
- Contextual — only appears when relevant
- Quick to use (2-3 taps)
- Natural flow during walk

**Cons:**
- Only works for walks (misses indoor exposures)
- Requires "active walk" state detection
- Quick-log bar already has potty buttons

---

### Option F: Post-Walk Summary

After ending a walk, show optional summary sheet:

```
Walk Complete: 15 min

Any socialization encounters?
[+ Add exposure]

Suggested (based on walk location):
• Cyclist (you're at 8/10!)
• Dog passing (recent negative)
```

**Pros:**
- Doesn't interrupt the walk
- Batch-log multiple exposures
- Uses walk context for suggestions

**Cons:**
- User might forget details
- Extra step after every walk
- Doesn't capture exact timing

---

## Key Questions to Resolve

### 1. Timeline Presence
Should exposures appear in the Today timeline at all?
- **Yes**: Creates a record of the day's socialization work
- **No**: Keep timeline clean, track progress in Plan only

### 2. Walk Relationship
Are exposures always part of a walk?
- **Yes**: Simplifies model (walk has exposures like potty events)
- **No**: Allows indoor/standalone exposures

### 3. Event Type
If exposures appear in timeline, are they:
- Enriched `sociaal` events (Option C)
- New `exposure` event type (Option D)
- Walk sub-events only (Option B)

### 4. Logging Friction
How many taps to log an exposure?
- **Quick** (2-3 taps): Distance + reaction buttons
- **Full** (4-5 taps): Item picker + distance + reaction + note

### 5. Spontaneous vs Planned
- **Spontaneous**: "Just saw a cyclist, log it quick!"
- **Planned**: "Going to practice vacuum cleaner exposure"

Different flows suit different scenarios.

## Recommendation for v2

Start with **Option C (enriched social events)** as the minimal viable integration:

1. Add `socializationItemId` and `exposureDistance` fields to PuppyEvent
2. When logging `.sociaal` event, show optional "Link to checklist?" picker
3. If linked, also ask for distance and show the reaction picker
4. This updates both: timeline shows event, Plan shows progress

**Why this approach:**
- Minimal data model changes
- Leverages existing event type
- User can ignore if they just want quick social log
- Natural discovery ("oh, I can track this for the checklist too!")

**For later consideration:**
- Quick-exposure mode during active walks
- Post-walk summary for batch logging
- Dedicated exposure event type if .sociaal becomes too overloaded

## Non-Walk Exposures

The vacuum cleaner question:

**Option 1: Log as social event anyway**
"Sociaal" is a misnomer — it's really "encounter/experience"
- Works but semantically weird

**Option 2: New event type**
`EventType.oefening` (practice) or `EventType.blootstelling` (exposure)
- Cleaner but adds complexity

**Option 3: Plan-only for non-walk items**
Indoor items (vacuum, handling, sounds) logged from Plan tab only
- Practical but inconsistent

**Recommendation:** For v2, keep indoor exposures in Plan tab only. Revisit if users request timeline visibility.

## Summary

| Aspect | v1 (Current) | v2 (Proposed) |
|--------|--------------|---------------|
| Exposure logging | Plan tab only | Plan + optional Today link |
| Timeline visibility | None | Social events can link to items |
| Walk sub-events | No | Not yet |
| Indoor exposures | Plan only | Plan only |
| Data model | Separate Exposure | Add fields to PuppyEvent |

The goal is to enable linking without forcing it, keeping the quick-log flow fast while allowing enrichment for users who want detailed tracking.
