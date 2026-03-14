# Ollie iOS — Puppy Logbook App

## Project
Native iOS app (SwiftUI, Swift) for tracking daily puppy/dog events. Works for any dog — user creates a profile during onboarding with name, birth date, home date, and size category. Supports multiple dogs and family sharing via CloudKit.

## Architecture

> **Full architecture documentation:** See `docs/ARCHITECTURE.md` for comprehensive patterns and examples.

### Pattern: MVVM with @Observable
- **Models/** — Data types (`PuppyEvent`, `EventType`, `PuppyProfile`, `MealSchedule`, etc.)
- **ViewModels/** — Business logic, state management (`TimelineViewModel`) — use `@Observable`
- **Views/** — SwiftUI views, composable and small
- **Services/** — Data persistence stores (`EventStore`, `ProfileStore`, etc.) — use `@Observable`
- **Utils/** — Helpers, extensions, constants

### State Management (IMPORTANT)

**Use Swift's Observation framework (iOS 17+), NOT ObservableObject.**

| Pattern | Usage |
|---------|-------|
| `@Observable` | All stores and view models |
| `@State` | View owns the observable (replaces `@StateObject`) |
| `@Bindable` | View needs bindings to observable properties (replaces `@ObservedObject`) |
| `@Environment` | Shared observable from ancestor (replaces `@EnvironmentObject`) |
| `@ObservationIgnored` | Properties excluded from observation |

```swift
// CORRECT
@Observable
@MainActor
class ProfileStore {
    var profile: PuppyProfile?
}

// In App
.environment(profileStore)

// In View
@Environment(ProfileStore.self) var profileStore

// WRONG - Do not use
class ProfileStore: ObservableObject {
    @Published var profile: PuppyProfile?
}
.environmentObject(profileStore)
@EnvironmentObject var profileStore: ProfileStore
```

### CloudKit Sync Architecture

CloudKit notifications flow through `CloudKitSyncCoordinator`:
1. Debounces rapid-fire notifications
2. Each store checks if its data ACTUALLY changed before reloading
3. Avoids cascade reloads and infinite loops

**Every store handling CloudKit changes must implement change detection:**
```swift
func handleRemoteChange() {
    let previousIds = Set(items.map { $0.id })
    let freshItems = fetchFromCoreData()

    // Skip if nothing changed
    if Set(freshItems.map { $0.id }) == previousIds {
        return
    }

    items = freshItems
}
```

**Never save to Core Data inside a sync handler** — this triggers new notifications and creates loops.

### Data Model

All data is stored in **Core Data with CloudKit** sync via `NSPersistentCloudKitContainer`.

**PuppyProfile** — stored in Core Data, provides computed properties: `ageInWeeks`, `ageInMonths`, `daysHome`, `maxExerciseMinutes`.

**PuppyEvent** — the core event entity with fields:
| Field | Type | When |
|-------|------|------|
| `time` | Date | Always |
| `type` | EventType enum | Always |
| `location` | `.buiten` / `.binnen` | Required for `plassen`, `poepen` |
| `note` | String | Optional, free text |
| `who` | String | `sociaal` events |
| `exercise` / `result` | String | `training` events |
| `durationMin` | Int | Optional duration |
| `photo` / `thumbnailPath` | String | Local file paths for media |

**Event types:** `eten`, `drinken`, `plassen`, `poepen`, `slapen`, `ontwaken`, `uitlaten`, `tuin`, `training`, `bench`, `sociaal`, `milestone`, `gedrag`, `gewicht`, `moment`

### Storage
- **Core Data with CloudKit** — `NSPersistentCloudKitContainer` for sync
- Private store: user's own data
- Shared store: data shared between family/partner accounts
- CloudKit sync handled by `CloudKitSyncCoordinator`
- Media files stored locally with CloudKit sync via `MediaCloudService`

### Constants
App-wide constants are in `Utils/Constants.swift`:
- `quickLogTypes` — event types shown in quick-log bar
- Layout constants, animation durations, etc.

User-specific values (birth date, bedtime hour, etc.) come from `PuppyProfile`.

## Localization (i18n)
English is the development language. Dutch, German, Spanish, and French translations are included.

### Infrastructure
- **`Utils/Strings.swift`** — All user-facing strings as namespaced constants
- **`Localizable.xcstrings`** — String Catalog with translations (JSON format)
- **`InfoPlist.xcstrings`** — System permission strings (camera, photos, etc.)

### Usage Pattern
```swift
// In views, use Strings constants:
Text(Strings.Common.cancel)
Text(Strings.Timeline.noEvents)

// For interpolation:
Text(Strings.Onboarding.breedQuestion(name: profile.name))

// Model enums use Strings in their label property:
eventType.label  // Returns localized string
```

### Adding New Strings
1. Add to `Strings.swift` with English text
2. Run build — Xcode extracts to String Catalog automatically
3. Add translations in `Localizable.xcstrings` when ready

### Supported Languages
- `en` — English (development language)
- `nl` — Dutch (translations included)
- `de` — German (translations included)
- `es` — Spanish (translations included)
- `fr` — French (translations included)
- `it` — Italian (translations included)
- `sv` — Swedish (translations included)

## Design Principles
- **Mobile-first UX** — Big tap targets, quick event logging (2 taps max for common events)
- **Timeline view** as home screen — today's events chronologically
- **FAB with radial menu** — floating action button for quick event logging
- **SwiftUI native** — use system components, SF Symbols
- **Dark mode support** from day one
- **Atmospheric UI** — dynamic backgrounds based on time of day and weather

## Key Features
1. **Onboarding** — new users create puppy profile (name, birth date, home date, size)
2. **Event logging** — tap to log, auto-timestamp, optional details
3. **Timeline view** — today's events with emoji, time, notes
4. **Day navigation** — pick date to see other days
5. **FAB (Floating Action Button)** — quick access to all event types
6. **Stats dashboard** — potty gaps, sleep analysis, meal tracking
7. **Potty predictions** — "time since last plas" + predicted next based on patterns
8. **Photo/video moments** — camera or library, stored with event, CloudKit synced
9. **Notifications** — potty reminders, walk suggestions, medication reminders
10. **Multi-dog support** — switch between profiles, shared household data
11. **Family sharing** — CloudKit shared zone for partner/family access
12. **AI insights** — morning briefings, health analysis, training guidance (Otis+)

## Business Logic
Calculation modules in `Calculations/` and `OtisShared/Sources/OtisShared/Calculations/`:
- Gap analysis — potty gap tracking, median/average intervals
- Predictions — next potty prediction with trigger adjustments
- Sleep analysis — night sleep, nap tracking, session building
- Pattern detection — behavioral patterns, trigger analysis
- Streaks — consecutive outdoor potty streaks

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
- Comments in English, UI strings in `Strings.swift`
- Git: commit messages in English, conventional commits style

## Task Files
One-time tasks and implementation briefs go in `TODO-<name>.md` files. Delete them when done. This file (CLAUDE.md) is for permanent project knowledge only.
