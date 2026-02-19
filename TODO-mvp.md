# TODO: MVP Setup

Set up the basic app structure and implement event logging + timeline view.

## Step 1: Project Structure
Create the folder/file structure:
```
Ollie-app/
  Models/
    PuppyEvent.swift        — Codable struct + EventType enum
  ViewModels/
    TimelineViewModel.swift — manages today's events, handles logging
  Views/
    TimelineView.swift      — scrollable list of today's events
    EventRow.swift           — single event in timeline (emoji + time + note)
    QuickLogBar.swift        — bottom bar with event type buttons
    LogEventSheet.swift      — sheet/modal for adding details (location, note, etc.)
  Services/
    EventStore.swift         — read/write JSONL files from documents dir
  Utils/
    Constants.swift          — birth date, emoji map, type labels
    DateHelpers.swift        — formatting, timezone handling
  OllieApp.swift             — app entry point (rename from Ollie_appApp.swift)
  ContentView.swift          — root view with tab navigation
```

## Step 2: Data Model
Implement `PuppyEvent` as a Codable struct that can serialize to/from the JSONL format. The JSON keys use snake_case (`duration_min`), Swift properties use camelCase.

## Step 3: Event Store
`EventStore` reads/writes `data/YYYY-MM-DD.jsonl` files in the app's documents directory. Each line is one JSON event. Append-only for logging (read full file, append line, write back).

## Step 4: Timeline View
Show today's events in a `List` or `LazyVStack`, newest at bottom (chat-style, chronological). Each row shows: emoji + time (HH:mm) + type label + note (if any).

## Step 5: Quick Log Bar
Fixed bottom bar with buttons for the most common events: 🚽 Plassen, 💩 Poepen, 🍽️ Eten, 😴 Slapen, ☀️ Wakker, 🚶 Uitlaten.

Tapping a button:
- For plassen/poepen: show a quick "Buiten/Binnen?" picker, then log
- For others: log immediately with current timestamp
- Optional: long-press to add a note

## Step 6: Seed Data
Include a few days of sample data (copy from the web app's `data/` folder) so the timeline isn't empty during development.

## Done Criteria
- [ ] Can log events by tapping quick-log buttons
- [ ] Events persist across app restarts (JSONL files)
- [ ] Timeline shows today's events with emoji + time + note
- [ ] Plassen/poepen asks buiten/binnen before logging

Delete this file when done.
