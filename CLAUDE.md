# Ollie iOS — Puppy Logbook App

## Project
Native iOS app (SwiftUI, Swift) for tracking daily puppy events. Sister project of the [Ollie web PWA](https://github.com/jaapstronks/Ollie). Works for any puppy — user creates a profile during onboarding with name, birth date, home date, and size category.

## Architecture

### Pattern: MVVM
- **Models/** — Data types (`PuppyEvent`, `EventType`, `PuppyProfile`, `MealSchedule`, etc.)
- **ViewModels/** — Business logic, state management (`TimelineViewModel`)
- **Views/** — SwiftUI views, composable and small
- **Services/** — Data persistence (`EventStore`, `ProfileStore`, `DataImporter`)
- **Utils/** — Helpers, extensions, constants

### PuppyProfile Model
Each app instance has a `PuppyProfile` stored in `profile.json`:
```swift
struct PuppyProfile: Codable {
    var name: String
    var breed: String?
    var birthDate: Date
    var homeDate: Date
    var sizeCategory: SizeCategory  // small, medium, large, extraLarge
    var mealSchedule: MealSchedule
    var exerciseConfig: ExerciseConfig
    var predictionConfig: PredictionConfig
}
```
Profile provides computed properties: `ageInWeeks`, `ageInMonths`, `daysHome`, `maxExerciseMinutes`.

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
App-wide constants (non-profile-specific) are in `Utils/Constants.swift`:
- `dataDirectoryName` — folder for JSONL files
- `profileFileName` — profile storage file
- `quickLogTypes` — event types shown in quick-log bar
- GitHub repo info for data import

User-specific values (birth date, bedtime hour, etc.) come from `PuppyProfile`.

## UI Language
Dutch. All labels, buttons, and text in Dutch.

## Design Principles
- **Mobile-first UX** — Big tap targets, quick event logging (2 taps max for common events)
- **Timeline view** as home screen — today's events chronologically
- **Quick-log bar** — persistent bottom bar with most common event types
- **SwiftUI native** — use system components, SF Symbols, no custom design system yet
- **Dark mode support** from day one

## Key Features (in order of priority)
1. **Onboarding** — new users create puppy profile (name, birth date, home date, size)
2. **Event logging** — tap to log, auto-timestamp, optional details
3. **Timeline view** — today's events with emoji, time, notes
4. **Day navigation** — pick date to see other days
5. **Quick-log bar** — bottom bar with common event types (plassen, poepen, eten, slapen, etc.)
6. **Stats dashboard** — potty gaps, sleep analysis, meal tracking
7. **Potty predictions** — "time since last plas" + predicted next based on patterns
8. **Data import** — import existing data from GitHub (Ollie web app repo)
9. **Settings** — view/edit profile, meal schedule, import data
10. **Photo attachment** — camera or library, stored with event (TODO)
11. **Notifications** — "het is X min geleden sinds laatste plas" (TODO)

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
