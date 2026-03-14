# Performance Optimization Plan

## Executive Summary

Analysis of app launch and Today view initialization revealed:
- **12+ Core Data fetches** at startup for overlapping date ranges
- **Double refresh cascade** on every event log
- **No shared event cache** - services fetch same data independently
- **25+ StateObjects** created immediately at app level

This plan addresses these issues in priority order.

---

## Phase 1: Eliminate Double Refresh (Quick Win)

**Problem:** When an event is logged, both `EventStore.$events` subscription AND `EventLoggingService.onEventsChanged` trigger the same refreshes.

**File:** `TimelineViewModel.swift`

**Fix:** Remove redundant callbacks from EventLoggingService - the EventStore subscription already handles updates.

```swift
// BEFORE (lines 445-448):
eventLoggingService.onEventsChanged = { [weak self] in
    self?.syncEventsFromStore()
    self?.statsCache.refresh(force: true)  // REDUNDANT
    self?.refreshPredictions()              // REDUNDANT
}

// AFTER:
eventLoggingService.onEventsChanged = { [weak self] in
    // Events already synced via EventStore.$events subscription
    // Stats and predictions already refreshed there too
    // Only need FirstWeekExperience update here
    FirstWeekExperienceService.shared.refreshCounts(from: self?.events ?? [])
}
```

**Impact:** 50% reduction in stats/prediction calculations per event.

---

## Phase 2: Shared Event Cache Layer

**Problem:** Multiple services fetch overlapping date ranges independently.

**Solution:** Create a centralized `EventDataProvider` that caches and shares event data.

### New File: `Services/EventDataProvider.swift`

```swift
/// Centralized event data provider with intelligent caching
/// Replaces individual service fetches with a single shared cache
@MainActor
final class EventDataProvider: ObservableObject {

    // MARK: - Dependencies
    private let eventStore: EventStore

    // MARK: - Cached Data (Published for reactive updates)
    @Published private(set) var todayEvents: [PuppyEvent] = []
    @Published private(set) var recentEvents: [PuppyEvent] = []      // 2 days
    @Published private(set) var weekEvents: [PuppyEvent] = []        // 7 days
    @Published private(set) var extendedEvents: [PuppyEvent] = []    // 15 days
    @Published private(set) var monthEvents: [PuppyEvent] = []       // 30 days

    // MARK: - Cache State
    private var lastRefresh: Date?
    private var refreshTask: Task<Void, Never>?
    private let cacheValidDuration: TimeInterval = 30 // seconds

    init(eventStore: EventStore) {
        self.eventStore = eventStore

        // Subscribe to event changes
        eventStore.$events
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] events in
                self?.todayEvents = events
                self?.refreshAllRangesIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    /// Force refresh all cached data
    func refresh(force: Bool = false) {
        guard force || shouldRefresh else { return }

        refreshTask?.cancel()
        refreshTask = Task {
            await refreshAllRanges()
        }
    }

    // MARK: - Private

    private var shouldRefresh: Bool {
        guard let lastRefresh else { return true }
        return Date().timeIntervalSince(lastRefresh) > cacheValidDuration
    }

    private func refreshAllRanges() async {
        let now = Date()
        let yesterday = now.addingDays(-1)
        let weekAgo = now.addingDays(-7)
        let fifteenDaysAgo = now.addingDays(-15)
        let monthAgo = now.addingDays(-30)
        let startOfToday = Calendar.current.startOfDay(for: now)

        // Single fetch for max range, then filter for smaller ranges
        let allEvents = await eventStore.getEventsAsync(from: monthAgo, to: now)

        guard !Task.isCancelled else { return }

        // Derive all ranges from single fetch (no additional DB queries)
        self.monthEvents = allEvents
        self.extendedEvents = allEvents.filter { $0.time >= fifteenDaysAgo }
        self.weekEvents = allEvents.filter { $0.time >= weekAgo }
        self.recentEvents = allEvents.filter { $0.time >= yesterday }
        // todayEvents already set from EventStore subscription

        self.lastRefresh = Date()
    }

    private var cancellables = Set<AnyCancellable>()
}
```

### Update Services to Use EventDataProvider

**TimelineStatsCache:**
```swift
// BEFORE:
let allRecentEvents = eventStore.getEvents(from: eightDaysAgo, to: Date())
let extendedEvents = eventStore.getEvents(from: fifteenDaysAgo, to: Date())

// AFTER:
let allRecentEvents = eventDataProvider.weekEvents  // Already cached
let extendedEvents = eventDataProvider.extendedEvents
```

**PredictionService:**
```swift
// BEFORE: 3 separate fetches
async let recentFetch = getRecentEventsAsync()
async let historicalFetch = getHistoricalEventsAsync(days: 7)
async let allFetch = getAllEventsAsync()

// AFTER: Use cached data
let recentEvents = eventDataProvider.recentEvents
let historicalEvents = eventDataProvider.weekEvents
let allEvents = eventDataProvider.monthEvents
```

**Impact:** Reduces 6+ overlapping fetches to 1 fetch with filtering.

---

## Phase 3: Debounce and Coalesce Updates

**Problem:** Every event change triggers immediate cascading updates.

**Solution:** Debounce the cascade to coalesce rapid changes.

### Update EventStore Subscription

```swift
// BEFORE (immediate):
eventStoreCancellable = eventStore.$events
    .receive(on: DispatchQueue.main)
    .sink { [weak self] loadedEvents in
        self?.events = loadedEvents
        self?.rebuildTimelineItems()
        self?.statsCache.refresh(force: true)
        self?.refreshPredictions()
    }

// AFTER (debounced cascade):
eventStoreCancellable = eventStore.$events
    .receive(on: DispatchQueue.main)
    .sink { [weak self] loadedEvents in
        guard let self else { return }
        // Sync immediately (UI needs this)
        self.events = loadedEvents
        self.rebuildTimelineItems()

        // Debounce expensive operations
        self.scheduleBackgroundRefresh()
    }

private var backgroundRefreshTask: Task<Void, Never>?

private func scheduleBackgroundRefresh() {
    backgroundRefreshTask?.cancel()
    backgroundRefreshTask = Task {
        // Wait 200ms for rapid events to coalesce
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }

        // Now refresh stats and predictions
        self.statsCache.refresh(force: true)
        self.refreshPredictions()
    }
}
```

**Impact:** Rapid event logging (e.g., bulk import) triggers single refresh instead of N refreshes.

---

## Phase 4: Lazy Store Initialization

**Problem:** 25+ stores created at app launch, even if unused.

**Solution:** Lazy initialization for non-essential stores.

### Create StoreContainer with Lazy Loading

```swift
/// Container for lazily-initialized stores
@MainActor
final class StoreContainer: ObservableObject {

    // MARK: - Core Stores (always needed)
    let profileStore: ProfileStore
    let eventStore: EventStore
    let eventDataProvider: EventDataProvider

    // MARK: - Lazy Stores (initialized on first access)

    private var _socializationStore: SocializationStore?
    var socializationStore: SocializationStore {
        if _socializationStore == nil {
            _socializationStore = SocializationStore(persistenceController: .shared)
        }
        return _socializationStore!
    }

    private var _trainingMasteryStore: TrainingMasteryStore?
    var trainingMasteryStore: TrainingMasteryStore {
        // Only created when user visits Training tab
        if _trainingMasteryStore == nil {
            _trainingMasteryStore = TrainingMasteryStore(persistenceController: .shared)
        }
        return _trainingMasteryStore!
    }

    // ... similar for other non-essential stores

    init() {
        self.profileStore = ProfileStore()
        self.eventStore = EventStore()
        self.eventDataProvider = EventDataProvider(eventStore: eventStore)
    }
}
```

### Categorize Stores

**Essential (create at launch):**
- ProfileStore
- EventStore
- EventDataProvider
- NotificationService
- SubscriptionManager

**Deferred (create on first tab visit):**
- SocializationStore (Training tab)
- SkillProgressStore (Training tab)
- TrainingMasteryStore (Training tab)
- SpotStore (Places tab)
- HealthStore (Health tab)
- DocumentStore (Health tab)
- WeightStore (Health tab)

**Lazy (create on feature use):**
- DataImporter (only for import)
- ContactStore (only for contacts feature)
- RegressionLogStore (only for behavior tracking)

**Impact:** Faster app launch, lower initial memory footprint.

---

## Phase 5: Optimize Photo Sync on Launch

**Problem:** `getEventsAsync(30 days)` for photo sync blocks other startup tasks.

**Current Code (Otis_appApp.swift:163-164):**
```swift
let recentEvents = await eventStore.getEventsAsync(from: Date.daysAgo(30), to: Date())
PhotoSyncService.shared.performInitialSync(events: recentEvents)
```

**Solution:** Move photo sync to after UI is ready.

```swift
// In performInitialSetup():
// Remove the blocking photo sync

// Add to MainTabView.onAppear or via background task:
.task(priority: .background) {
    // Wait for UI to be responsive
    try? await Task.sleep(for: .seconds(2))

    // Now sync photos
    let recentEvents = await eventStore.getEventsAsync(from: Date.daysAgo(30), to: Date())
    PhotoSyncService.shared.performInitialSync(events: recentEvents)
}
```

**Impact:** App UI appears faster; photo sync happens in background.

---

## Phase 6: Tiered Calculation Strategy

**Problem:** All calculations (patterns, streaks, predictions, stats) run on every event change.

**Solution:** Tier calculations by urgency.

### Tier 1: Immediate (needed for UI)
- Sleep state
- Potty prediction
- Combined status card

### Tier 2: Deferred (can wait 500ms)
- Poop status
- Daily digest
- Streak info

### Tier 3: Background (can wait seconds)
- Pattern analysis
- Week stats
- Walk stats
- Historical trends

### Implementation

```swift
func refreshPredictions() {
    Task {
        // Tier 1: Immediate UI updates
        await refreshImmediatePredictions()

        // Tier 2: Deferred updates (after 500ms)
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await refreshDeferredCalculations()
    }
}

private func refreshImmediatePredictions() async {
    // Only calculate what's needed for status cards
    let recentEvents = eventDataProvider.recentEvents

    predictionService.refreshImmediate(
        todayEvents: events,
        recentEvents: recentEvents
    )
}

private func refreshDeferredCalculations() async {
    // Calculate less urgent data
    predictionService.refreshDeferred(
        historicalEvents: eventDataProvider.weekEvents,
        allEvents: eventDataProvider.monthEvents
    )
}
```

**Impact:** Status cards update instantly; secondary data follows shortly after.

---

## Implementation Priority

| Phase | Effort | Impact | Status |
|-------|--------|--------|--------|
| Phase 1: Eliminate Double Refresh | Low | High | ✅ **DONE** |
| Phase 2: Shared Event Cache | Medium | High | ✅ **DONE** |
| Phase 3: Debounce Updates | Low | Medium | ✅ **DONE** |
| Phase 5: Photo Sync Background | Low | Medium | ✅ **DONE** |
| Phase 4: Deferred Store Loading | Medium | Medium | ✅ **DONE** |
| Phase 6: Tiered Calculations | High | Medium | Pending |

---

## Expected Results

### Before Optimization
- App launch: 12+ Core Data fetches
- Event log: 6+ fetches, 2x calculations
- Memory at launch: ~15MB+ (all stores)

### After Optimization
- App launch: 3-4 Core Data fetches
- Event log: 0 additional fetches (cached), 1x calculations
- Memory at launch: ~8MB (essential stores only)

### Measurable Targets
- [ ] Reduce startup Core Data fetches by 60%
- [ ] Eliminate duplicate refresh cascade
- [ ] App launch to interactive < 500ms
- [ ] Event log to UI update < 100ms
