# TODO: V2 — Make it actually useful

(COMPLETED)

Three improvements that make the app a daily driver instead of a demo.

## Step 1: Time Adjustment on Log

When logging an event, default to "now" but make it trivially easy to adjust:

- Show current time as a tappable/editable field in the logging flow
- Quick buttons: **-5 min**, **-10 min**, **-15 min**, **-30 min** (most common: "ze plaste net, even loggen")
- Tapping the time field opens a time picker for exact selection
- This applies to ALL event types, not just potty

Implementation: modify `QuickLogBar` and `LocationPickerSheet` to include a time row. For non-potty events, show a small confirmation toast/sheet with the time adjustment option before saving (instead of logging instantly).

Suggested UX flow:

1. Tap quick-log button (e.g. 🍽️ Eten)
2. Small sheet slides up: **"Eten — 09:23"** with [-5] [-10] [-15] buttons and a time picker
3. Tap "Log" (or the time is already fine, tap the big ✅ button)
4. For plassen/poepen: same sheet but with buiten/binnen picker added

This replaces the current "log instantly" behavior for non-potty events and extends the LocationPickerSheet for potty events.

## Step 2: Time Since Last Plas — Hero Widget

Add a prominent card at the top of the timeline view:

```
┌─────────────────────────────┐
│  🚽  47 min geleden         │
│  Laatste plas: 08:36 buiten │
└─────────────────────────────┘
```

- Shows minutes since last `plassen` event (today, or yesterday if none today)
- Color coding: green (<60 min), orange (60-90 min), red (>90 min) — thresholds based on actual median gap from data
- Tapping it could later link to predictions/stats
- If no plas today yet: "Nog niet geplast vandaag"
- Night mode (23:00-06:00): hide or dim

Implementation: add a `PottyStatusCard` view above the event list in `TimelineView`. Calculate from `viewModel.events` — find last event where `type == .plassen`, compute time difference.

## Step 3: More Event Types via Expandable Bar

The quick-log bar currently shows 6 types. Add access to all types:

- Add a **"＋"** button at the end of the quick-log bar
- Tapping it opens a grid/sheet with ALL event types
- Grid layout: 3-4 columns, each cell is emoji + label
- Includes: tuin, training, bench, sociaal, drinken, milestone, gedrag, gewicht
- Same logging flow (time adjustment sheet → optional note → save)

## Step 4: Notes on Events

Add optional note input to the logging sheet (from Step 1):

- Text field at the bottom of the confirmation sheet: "Notitie (optioneel)"
- Single line, placeholder text like "Bijv. na het eten, in de tuin..."
- Pressing return or tapping "Log" saves with note
- Keep it optional — don't add friction to quick logging

## Done Criteria

- [x] Can adjust timestamp when logging (quick buttons + time picker) → `QuickLogSheet.swift`
- [x] "Tijd sinds laatste plas" card visible at top of timeline → `PottyStatusCard.swift`
- [x] Card color changes based on time elapsed → urgency-based coloring in PottyStatusCard
- [x] Can access all event types via "+" button → `MoreEventsButton` + `AllEventsSheet.swift`
- [x] Can add optional note to any event → note field in `QuickLogSheet.swift`
- [x] TODO-mvp.md is deleted (MVP is done)

✅ **All V2 features implemented.** This file can be deleted.
