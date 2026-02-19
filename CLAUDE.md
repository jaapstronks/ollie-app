# Ollie iOS — Puppy Logbook App

## Project
Native iOS app (SwiftUI, Swift) for tracking daily puppy events. Sister project of the [Ollie web PWA](https://github.com/jaapstronks/Ollie). Built for a Golden Retriever puppy born 2025-12-20, home since 2026-02-14.

## Architecture

### Pattern: MVVM
- **Models/** — Data types (`PuppyEvent`, `EventType`, enums)
- **ViewModels/** — Business logic, state management (`TimelineViewModel`, `StatsViewModel`)
- **Views/** — SwiftUI views, composable and small
- **Services/** — Data persistence, calculations, predictions
- **Utils/** — Helpers, extensions, constants

### Data Model
Events are stored as JSONL (one JSON object per line), same format as the web app:
```json
{"time":"2026-02-19T08:15:00+01:00","type":"sociaal","who":"Buurhond Sasha","note":"Kennismaking","photo":"https://..."}
```

**Event types:** `eten`, `drinken`, `plassen`, `poepen`, `slapen`, `ontwaken`, `uitlaten`, `tuin`, `training`, `bench`, `sociaal`, `milestone`, `gedrag`, `gewicht`

**Key fields:**
| Field | Type | When |
|-------|------|------|
| `time` | ISO 8601 with timezone (+01:00 / +02:00) | Always |
| `type` | String (see above) | Always |
| `location` | `"buiten"` / `"binnen"` | Required for `plassen`, `poepen` |
| `note` | String | Optional, free text |
| `who` | String | `sociaal` events |
| `exercise` / `result` | String | `training` events |
| `duration_min` | Int | Optional duration |
| `photo` / `video` | URL string | Optional media |

### Storage
- Local JSONL files in app documents directory: `data/YYYY-MM-DD.jsonl`
- Same format as web app for potential data portability
- No Core Data, no SwiftData — keep it simple

### Constants
```swift
let birthDate = DateComponents(calendar: .current, year: 2025, month: 12, day: 20).date!
let startDate = DateComponents(calendar: .current, year: 2026, month: 2, day: 14).date!
let bedtimeHour = 22
let minNapDurationForPottyTrigger = 15 // minutes
```

## UI Language
Dutch. All labels, buttons, and text in Dutch.

## Design Principles
- **Mobile-first UX** — Big tap targets, quick event logging (2 taps max for common events)
- **Timeline view** as home screen — today's events chronologically
- **Quick-log bar** — persistent bottom bar with most common event types
- **SwiftUI native** — use system components, SF Symbols, no custom design system yet
- **Dark mode support** from day one

## Key Features (in order of priority)
1. **Event logging** — tap to log, auto-timestamp, optional details
2. **Timeline view** — today's events with emoji, time, notes
3. **Day navigation** — swipe or pick date to see other days
4. **Stats dashboard** — potty gaps, sleep analysis, meal tracking
5. **Potty predictions** — "time since last plas" + predicted next based on patterns
6. **Photo attachment** — camera or library, stored with event
7. **Notifications** — "het is X min geleden sinds laatste plas"

## Business Logic (port from web app)
The web app (JS) has battle-tested calculation modules to port:
- `calculations/gaps.js` — potty gap analysis, median/average intervals
- `calculations/predictions.js` — next potty prediction with trigger adjustments
- `calculations/sleep.js` — night sleep analysis, nap tracking
- `calculations/patterns.js` — behavioral pattern detection
- `calculations/streaks.js` — consecutive outdoor potty streaks

**Important rule:** Naps < 15 minutes count toward total sleep time but do NOT trigger post-sleep potty predictions.

## Build & Run
- Open `Ollie-app.xcodeproj` in Xcode
- Select iPhone simulator or connected device
- `Cmd+R` to build and run
- Or from terminal: `xcodebuild -scheme Ollie-app -destination 'platform=iOS Simulator,name=iPhone 16'`

## Conventions
- Swift naming conventions (camelCase properties, PascalCase types)
- SwiftUI previews for every view
- No external dependencies (SPM packages) unless absolutely necessary
- Comments in English, UI in Dutch
- Git: commit messages in English, conventional commits style

## Task Files
One-time tasks and implementation briefs go in `TODO-<name>.md` files. Delete them when done. This file (CLAUDE.md) is for permanent project knowledge only.
