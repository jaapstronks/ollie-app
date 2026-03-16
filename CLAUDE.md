# Ollie iOS — Puppy Logbook App

## Project
Native iOS app (SwiftUI, Swift) for tracking daily puppy/dog events. Works for any dog — user creates a profile during onboarding with name, birth date, home date, and size category. Supports multiple dogs and family sharing via CloudKit.

## Architecture

> **Full architecture documentation:** See `docs/ARCHITECTURE.md` for comprehensive patterns and examples.

### Pattern: MVVM with @Observable
- **Models/** — Data types (`PuppyEvent`, `EventType`, `PuppyProfile`, `MealSchedule`, etc.)
- **ViewModels/** — Business logic, state management (`TimelineViewModel`) — use `@Observable`
- **Views/** — SwiftUI views, composable and small
- **Services/** — Organized into subdirectories (see below)
- **Utils/** — Helpers, extensions, constants

### Services Folder Structure
```
Services/
├── AI/              — AI orchestration, nudges, context building
├── Analytics/       — Analytics, crash reporting
├── Discovery/       — Location discovery (dog parks, amenities)
├── Features/        — Feature services (walks, achievements, export)
├── Health/          — Health/wellness services
├── Integration/     — External APIs (weather, maps, breed)
├── Media/           — Photo/media handling
├── Notifications/   — Notification schedulers
├── Onboarding/      — First week experience
├── Sharing/         — Sharing services
├── Stores/          — Core Data CRUD stores (`*Store.swift`)
├── Subscription/    — Premium features
├── Sync/            — CloudKit sync, migrations
├── Timeline/        — Timeline services
├── Training/        — Training engine
└── [root]           — Core infrastructure (PersistenceController, etc.)
```

**Naming conventions:**
- `*Store` — Core Data CRUD operations (e.g., `EventStore`, `ProfileStore`)
- `*Service` — Business logic, external integrations (e.g., `WeatherService`)
- Acceptable variants: `*Manager`, `*Provider`, `*Builder`, `*Generator` for specific patterns

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

### CloudKit Sync Architecture (CKSyncEngine)

Ollie uses **CKSyncEngine** (iOS 17+, WWDC23) for CloudKit sync instead of NSPersistentCloudKitContainer. This provides sub-second sync, manual triggers, and direct CloudKit control.

**Key components** (in `OtisShared/Sources/OtisShared/CloudKit/`):
- **SyncCoordinator** — Central singleton managing private + shared database sync
- **SyncEngine** — Wrapper around Apple's CKSyncEngine (one per database)
- **CKRecordConvertible** — Protocol for Core Data ↔ CKRecord conversion
- **EntitySyncHandler** — Protocol for entity-specific sync handling

**When saving/deleting entities:**
```swift
// Save to Core Data first
try? viewContext.save()

// Then queue for CloudKit sync
SyncCoordinator.shared.markPendingSave(entity)

// For deletions: queue BEFORE deleting locally
SyncCoordinator.shared.markPendingDelete(entity)
viewContext.delete(entity)
```

**Manual sync triggers:**
```swift
await SyncCoordinator.shared.fetchChanges()  // Pull-to-refresh
await SyncCoordinator.shared.sendChanges()   // Sync now
await SyncCoordinator.shared.sync()          // Full sync
```

See `docs/ARCHITECTURE.md` for detailed sync flow diagrams and conflict resolution.

### Data Model

All data is stored in **Core Data** locally, with CloudKit sync via **CKSyncEngine**.

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
- **Core Data** — `NSPersistentContainer` for local persistence (NOT CloudKit container)
- **CKSyncEngine** — Handles CloudKit sync (iOS 17+, sub-second sync)
- Private database: user's own data
- Shared database: data shared with family/partner via CKShare
- **SyncCoordinator** — Central orchestrator for both private and shared sync engines
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

### Calculations Architecture

Calculations are split between two folders based on dependency requirements:

**`OtisShared/Sources/OtisShared/Calculations/`** — Shared package (17 files)
- Pure calculation logic with no iOS-specific dependencies
- Used by main app, widgets, and watch app
- Examples: `GapCalculations`, `SleepCalculations`, `WalkCalculations`, `StreakCalculations`

**`Ollie-app/Calculations/`** — App-specific (10 files)
- Calculations that depend on iOS-only types or app services
- Can extend shared calculations with iOS-specific functionality
- Examples: `PredictionCalculations`, `NudgeCalculations`, `StreakCalculations+iOS` (extends shared)

**Rule:** If a calculation can run without iOS-specific imports, put it in `OtisShared`. Only use `Ollie-app/Calculations/` when you need UIKit, app-specific services, or Core Data entities.

### Key Calculation Modules
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
