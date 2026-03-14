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

### The Problem We Solved

Previously, each store independently listened to CloudKit notifications:
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

### The Solution

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
