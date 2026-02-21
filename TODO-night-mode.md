# TODO: Night Quick-Log Mode

## Overview
Port the web app's night quick-log panel. During nighttime potty breaks, you want to log events with minimal screen brightness and interaction — no fumbling through the full UI at 3am.

## Priority: Low-Medium
Useful but niche — only needed during the early weeks when nighttime potty breaks are frequent. May become less relevant as Ollie grows.

## Features

### 1. Night Mode Detection
Activate between 22:00–07:00 (configurable). Can be:
- Automatic (based on time)
- Manual toggle
- Triggered by device dark mode + time

### 2. Night Quick-Log Panel
Full-screen dark overlay with minimal UI:
- Very dim, warm-toned display (protect night vision)
- Large tap targets for common night events:
  - 🚽 Plassen (buiten) — one tap
  - 💩 Poepen (buiten) — one tap
  - 🚽⚠️ Plassen (binnen) — one tap
  - 😴 Slapen — one tap
  - ☀️ Wakker — one tap
- Auto-timestamps with current time
- Minimal confirmation (subtle haptic, brief flash)
- No bright colors, no animations

### 3. Night Log Queue (Web App Feature)
The web app queues night events and syncs them later. For the iOS app this is less relevant since events are stored locally, but consider:
- Offline resilience (already handled by EventStore)
- Batch review: "Je hebt 3 events gelogd vannacht" summary in the morning

### 4. Auto-Return to Sleep
After logging, auto-dismiss back to a minimal clock/dark screen after 3 seconds.

## Files to Create/Modify
- `Views/NightQuickLogView.swift` — the night mode overlay
- `Utils/NightModeHelper.swift` — time-based detection
- Modify `ContentView.swift` or `TimelineView.swift` to present night mode

## Design Notes
- Think of this as a "quick action sheet" optimized for darkness
- Maximum contrast reduction — dark grays, not blacks and whites
- Large buttons (minimum 60pt tap target)
- Consider reducing screen brightness programmatically (if possible)
- The web app uses orange-tinted colors for night mode
- One-tap logging is key — the whole point is speed in the dark
