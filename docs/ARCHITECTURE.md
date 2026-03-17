# Ollie App Architecture

This document defines the architectural patterns used in the Ollie iOS app. All new code should follow these patterns, and existing code should be migrated to align with them.

## Core Principles

### 1. Single Source of Truth
Each piece of data has exactly ONE owner. Views derive state from the source of truth; they do not cache copies.

### 2. Granular Observation
Use Swift's `@Observable` macro (iOS 17+) instead of `ObservableObject`. This ensures views only re-render when the specific properties they access change, not when ANY property changes.

### 3. Coordinated Sync
CloudKit notifications flow through a single coordinator that determines what actually changed before notifying specific stores.

---

## State Management Patterns

### Observable Models

**DO:**
```swift
@Observable
@MainActor
class ProfileStore {
    var profile: PuppyProfile?
    var isLoading: Bool = false

    // Properties excluded from observation
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
}
```

**DON'T:**
```swift
// Legacy pattern - do not use
class ProfileStore: ObservableObject {
    @Published var profile: PuppyProfile?
    @Published var isLoading: Bool = false
}
```

### Property Wrappers

| Old (ObservableObject) | New (@Observable) | Usage |
|------------------------|-------------------|-------|
| `@StateObject` | `@State` | View owns the model |
| `@ObservedObject` | `@Bindable` | View needs bindings to model properties |
| `@EnvironmentObject` | `@Environment` | Shared model from ancestor |
| `@Published` | (not needed) | All stored properties auto-observed |

### Environment Injection

**DO:**
```swift
// In parent view
ContentView()
    .environment(profileStore)

// In child view
@Environment(ProfileStore.self) var profileStore
```

**DON'T:**
```swift
// Legacy pattern - do not use
ContentView()
    .environmentObject(profileStore)

@EnvironmentObject var profileStore: ProfileStore
```

### When to Use @Bindable

Use `@Bindable` only when you need two-way bindings to observable object properties:

```swift
struct EditProfileView: View {
    @Bindable var profileStore: ProfileStore

    var body: some View {
        TextField("Name", text: $profileStore.profile.name)
    }
}
```

If you only read properties (no bindings needed), use `@Environment` or pass directly:

```swift
struct ProfileDisplayView: View {
    let profile: PuppyProfile  // Just pass the data

    var body: some View {
        Text(profile.name)
    }
}
```

---

## CloudKit Sync Architecture

### CKSyncEngine (iOS 17+)

Ollie uses **CKSyncEngine** (introduced iOS 17, WWDC23) instead of NSPersistentCloudKitContainer. This provides:

- **Sub-second sync** when conditions allow (vs 1-5 minute delays with NSPersistentCloudKitContainer)
- **Manual sync triggers** for pull-to-refresh, widget updates, Watch sync
- **Explicit conflict resolution** - we control how conflicts are resolved
- **Better error visibility** - all errors are surfaced to the app
- **Direct CloudKit control** - enables webhooks, server-to-server APIs, Siri/Shortcuts integration

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        SyncCoordinator                          │
│                    (Central orchestrator)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────────────┐    ┌─────────────────────┐           │
│   │   SyncEngine        │    │   SyncEngine        │           │
│   │   (Private DB)      │    │   (Shared DB)       │           │
│   │                     │    │                     │           │
│   │ ┌─────────────────┐ │    │ ┌─────────────────┐ │           │
│   │ │ CKSyncEngine    │ │    │ │ CKSyncEngine    │ │           │
│   │ │ (Apple API)     │ │    │ │ (Apple API)     │ │           │
│   │ └─────────────────┘ │    │ └─────────────────┘ │           │
│   └─────────────────────┘    └─────────────────────┘           │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                     Entity Handlers                              │
│   ProfileSyncHandler, EventSyncHandler, MedicationSyncHandler...│
│   (Convert Core Data ↔ CKRecord)                                │
└─────────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│              Core Data (Local Persistence Only)                  │
│              NSPersistentContainer (NOT CloudKit)               │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

**SyncCoordinator** (`OtisShared/CloudKit/SyncCoordinator.swift`):
- Singleton managing both private and shared database sync engines
- Registers entity handlers for each Core Data entity type
- Provides `markPendingSave()` / `markPendingDelete()` for stores to queue changes
- Handles account changes (sign in/out/switch)

**SyncEngine** (`OtisShared/CloudKit/SyncEngine.swift`):
- Wrapper around Apple's CKSyncEngine
- One instance per database (private + shared)
- Handles state persistence, push notifications, scheduler tasks
- Provides manual sync: `fetchChanges()`, `sendChanges()`

**CKRecordConvertible** (`OtisShared/CloudKit/CKRecordConvertible.swift`):
- Protocol for entities that sync via CKSyncEngine
- Defines `toCKRecord()` and `update(from:)` for conversion
- Stores system fields for conflict detection

**EntitySyncHandler**:
- Protocol for handling sync of specific entity types
- Fetches CKRecords for pending saves
- Applies fetched records to Core Data
- Handles deletions

### Sync Flow

**Sending Changes:**
```
1. Store saves to Core Data
2. Store calls SyncCoordinator.markPendingSave(entity)
3. SyncCoordinator queues the change with appropriate SyncEngine
4. CKSyncEngine consults system scheduler
5. When ready, CKSyncEngine asks delegate for next batch
6. EntityHandler converts Core Data → CKRecord
7. CKSyncEngine sends to server
8. On success/failure, delegate updates system fields
```

**Fetching Changes:**
```
1. CloudKit sends push notification
2. CKSyncEngine receives and schedules fetch
3. System scheduler approves fetch
4. CKSyncEngine fetches from server
5. Delegate receives fetched records
6. EntityHandler converts CKRecord → Core Data
7. Stores are notified of changes
```

### Usage in Stores

```swift
@Observable
@MainActor
class EventStore {
    func saveEvent(_ event: CDPuppyEvent) {
        // Save to Core Data
        try? viewContext.save()

        // Queue for CloudKit sync
        SyncCoordinator.shared.markPendingSave(event)
    }

    func deleteEvent(_ event: CDPuppyEvent) {
        // Queue deletion for CloudKit BEFORE deleting locally
        SyncCoordinator.shared.markPendingDelete(event)

        // Then delete from Core Data
        viewContext.delete(event)
        try? viewContext.save()
    }
}
```

### Manual Sync Triggers

```swift
// Pull-to-refresh
await SyncCoordinator.shared.fetchChanges()

// Sync now button
await SyncCoordinator.shared.sendChanges()

// Full sync (send + fetch)
await SyncCoordinator.shared.sync()
```

### Conflict Resolution

When the server has a newer version (serverRecordChanged error):
1. CKSyncEngine provides the server's version
2. EntityHandler applies server version to local Core Data
3. Local changes are lost (server wins by default)
4. For critical data, implement custom merge logic in EntityHandler

### Account Change Handling

SyncCoordinator handles iCloud account changes per Apple's recommendations:

**Sign In:**
- Enable sync and fetch all data from CloudKit

**Sign Out:**
- Disable sync
- Delete all locally synced data (prevents data leaking to wrong account)
- Reset pending changes count

**Account Switch:**
- Delete locally synced data
- Re-enable sync
- Fetch all data for new account

**Zone Purge (left share):**
- Delete local data associated with that zone
- Notify observers of changes

Entity handlers implement `handleAccountSignOut()` and `handleZonePurge()` for entity-specific cleanup.

### Two-Database Architecture

- **Private Database**: User's own data (profile, events, settings)
- **Shared Database**: Data shared with family/partner via CKShare

Each database has its own SyncEngine instance. The SyncCoordinator manages both.

### State Persistence

CKSyncEngine requires persisting state to survive app restarts:

```swift
// State is stored in UserDefaults
private var stateKey: String {
    "SyncEngineState_\(configuration.identifier)"
}

// Saved on every state update event
func handleEvent(_ event: CKSyncEngine.Event, ...) {
    case .stateUpdate(let stateUpdate):
        saveStateSerialization(stateUpdate.stateSerialization)
}
```

### Why Not NSPersistentCloudKitContainer?

NSPersistentCloudKitContainer is simpler but has limitations:
- **Sync delays**: 1-5 minutes typical, sometimes longer
- **No manual triggers**: Can't force sync for widgets, Watch, etc.
- **Opaque errors**: Hard to debug sync issues
- **No direct CloudKit access**: Can't use webhooks, server APIs
- **Shared database quirks**: Complex setup for family sharing

CKSyncEngine gives us control while still handling the hard parts (scheduling, retries, state tracking).

### References

- [WWDC23: Sync to iCloud with CKSyncEngine](https://developer.apple.com/videos/play/wwdc2023/10188/)
- [CKSyncEngine Documentation](https://developer.apple.com/documentation/cloudkit/cksyncengine)

---

## Legacy: CloudKitSyncCoordinator (Pre-CKSyncEngine)

> **Note**: This section documents the previous approach using NSPersistentCloudKitContainer. It's kept for reference during migration.

### The Problem

When using NSPersistentCloudKitContainer, stores independently listened to CloudKit notifications:
```
CloudKit Notification
    ├─→ EventStore.handleRemoteChange() → full reload
    ├─→ ProfileStore.handleRemoteChange() → full reload
    ├─→ MedicationStore.handleRemoteChange() → full reload
    ├─→ ... (10+ stores, all reloading everything)
```

This caused:
- Massive cascade of reloads on every notification
- Notifications fire for WAL checkpoints (local operations), not just actual remote changes
- Core Data saves trigger new notifications → infinite loops

### Legacy Solution

```
CloudKit Notification (NSPersistentStoreRemoteChange)
        ↓
CloudKitSyncCoordinator (single entry point)
        ↓
    1. Debounce rapid-fire notifications
    2. Determine what ACTUALLY changed
    3. Notify ONLY affected stores
        ↓
    Each store checks if its data changed
        ↓
    Only reload if necessary
        ↓
    @Observable ensures views only update for accessed properties
```

### Change Detection Pattern

Every store that handles CloudKit changes should check if data actually changed:

```swift
func handleRemoteChange() {
    // Capture current state
    let previousIds = Set(items.map { $0.id })

    // Read fresh data
    let freshItems = fetchFromCoreData()
    let freshIds = Set(freshItems.map { $0.id })

    // Skip if nothing changed
    if freshIds == previousIds && freshItems.count == items.count {
        logger.debug("No actual changes, skipping refresh")
        return
    }

    // Actual changes - do the work
    items = freshItems
}
```

---

## Store Architecture

### Store Responsibilities

Each store should:
1. Own its Core Data entity type
2. Provide read/write access to its data
3. Handle its own CloudKit change detection
4. NOT trigger cascading reloads of other stores

### Store Dependencies

Stores can reference other stores but should not reload them:

```swift
@Observable
@MainActor
class EventStore {
    // Reference to profile store for filtering
    private weak var profileStoreRef: ProfileStore?

    func setProfileStore(_ store: ProfileStore) {
        profileStoreRef = store
    }

    // Use profile data but don't reload ProfileStore
    func loadEvents(for date: Date) {
        guard let profileId = profileStoreRef?.profile?.id else { return }
        // Load events for this profile
    }
}
```

---

## View Architecture

### View Hierarchy for Data

```
OtisApp (owns @State stores)
    │
    ├─ .environment(profileStore)
    ├─ .environment(eventStore)
    ├─ .environment(...)
    │
    └─ ContentView
        └─ MainTabView
            ├─ TodayView (@Environment stores, @Bindable viewModel)
            ├─ TrainView
            └─ ...
```

### ViewModel Pattern

ViewModels coordinate between multiple stores and provide derived state:

```swift
@Observable
@MainActor
class TimelineViewModel {
    // Injected dependencies
    private let eventStore: EventStore
    private let profileStore: ProfileStore

    // Derived state (computed or updated by methods)
    var timelineItems: [TimelineItem] = []
    var predictions: PottyPrediction?

    // Trigger for forcing updates when external state changes
    var refreshTrigger: Int = 0
}
```

---

## Migration Status

**✅ Migration Complete** - All stores, services, and ViewModels now use `@Observable`.

### Stores (via BaseStore/CRUDStore)
- ProfileStore, EventStore, BaseStore, CRUDStore
- MedicationStore, SocializationStore, SkillProgressStore, RegressionLogStore
- RoutineStore, TrainingPlanStore, SpotStore, ContactStore
- MilestoneStore, DocumentStore, AppointmentStore, WeightStore

### Standalone Services
- SubscriptionManager, WeatherService, NotificationService, LocationManager
- TrialManager, UnitPreferences, CloudKitService, CloudKitShareManager
- DogParkDiscoveryService, TrainingProgressStore, UserIdentityStore, TrainingMasteryStore
- ActivityTrackingManager, AtmosphereProvider, ErrorHandling

### ViewModels
- TimelineViewModel, SheetCoordinator, ThisWeekViewModel, TodayStatusViewModel
- MomentsViewModel, MemoriesViewModel, PlacesMapViewModel
- MonthRecapViewModel, WeekRecapViewModel, YearRecapViewModel
- ContributionStatsViewModel, MorningBriefingViewModel, PottyTrainingGuideViewModel
- AppNavigationState, MediaCaptureViewModel

### Watch App
- WatchDataProvider - Uses `@Observable @MainActor` with WatchConnectivity

---

## Performance Guidelines

### Avoid

1. **Reloading all data on any change**
   ```swift
   // Bad: Reloads everything
   func handleAnyChange() {
       loadAllData()
   }
   ```

2. **Cascading notifications**
   ```swift
   // Bad: One store triggers another
   func handleRemoteChange() {
       otherStore.reload()  // Don't do this
   }
   ```

3. **Saving during sync handling**
   ```swift
   // Bad: Creates notification loop
   func handleRemoteChange() {
       recomputeAggregates()  // This saves to Core Data
       // → triggers new notification → infinite loop
   }
   ```

### Do

1. **Check before reloading**
2. **Debounce rapid notifications**
3. **Use lazy computation for aggregates**
4. **Let @Observable handle granular updates**

---

## References

- [Discover Observation in SwiftUI - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [Migrating from ObservableObject to Observable](https://developer.apple.com/documentation/SwiftUI/Migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [SwiftUI Essentials - WWDC24](https://developer.apple.com/videos/play/wwdc2024/10150/)
