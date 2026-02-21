# TODO: Poop Slot Tracker

## Overview
Port the web app's PoopTimer component. Ollie poops ~2x/day in predictable time windows. This tracker shows which slots are filled and alerts when one is overdue.

## Priority: Medium
Practical daily tool — helps notice when the afternoon poop is missing before it becomes an indoor accident.

## Features

### 1. Poop Slot Model
Two daily poop windows:

```swift
struct PoopSlot: Identifiable {
    let id: String        // "ochtend" or "middag"
    let label: String     // "Ochtend" or "Eind middag"
    let startHour: Int    // 4 or 13
    let endHour: Int      // 13 or 21
}

static let slots: [PoopSlot] = [
    PoopSlot(id: "ochtend", label: "Ochtend", startHour: 4, endHour: 13),
    PoopSlot(id: "middag", label: "Eind middag", startHour: 13, endHour: 21)
]
```

A slot is "filled" if any poop event today falls within its time window.

### 2. Status Card UI
Compact card showing:
- 💩 icon
- Slot indicators: `✅ Ochtend` `○ Eind middag`
- Time since last poop: "2u15 geleden"
- Status-dependent styling and messaging

### 3. Alert Logic
| Condition | Message | Style |
|-----------|---------|-------|
| Ochtend missing, 06:00–13:00 | "Ochtend-poep nog niet geweest" | Normal |
| Middag missing, 17:00–19:00 | "Middag-poep nog niet geweest — verwacht 17:00–19:00" | Attention |
| Middag missing, 19:00+ | "Middag-poep mist nog! Neem haar even mee naar buiten" | Urgent |
| Both done | "Beide poepjes gedaan ✓" | Good/green |
| Night (23:00–06:00) | Hidden | — |

### 4. Integration with Notifications
If `NotificationService` is set up, consider a push notification at 19:00 if the afternoon slot isn't filled.

## Files to Create/Modify
- `Views/PoopStatusCard.swift` — new card component
- `Calculations/PoopCalculations.swift` — slot checking, time-since calculations
- `Views/TimelineView.swift` — add PoopStatusCard alongside existing PottyStatusCard

## Design Notes
- Place next to or below the existing PottyStatusCard on the timeline
- Use the same card style (glass card)
- Color coding: green (done), orange (attention), red (urgent)
- The web app hides this at night — do the same
- Existing `PottyStatusCard` handles the pee timer; this is specifically for poop slots
