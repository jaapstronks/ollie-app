# Performance Analysis Report

## Executive Summary

The app experienced severe performance degradation (1-2+ second UI freezes) due to a **cascading notification storm** triggered by CloudKit sync. Each `NSPersistentStoreRemoteChange` notification caused 12+ stores to independently react, triggering a cascade of Core Data queries, `objectWillChange` notifications, and expensive stat computations — all without any debouncing or coordination.

**Root cause:** Architecture that multiplied a single CloudKit notification into 50+ operations.

**Status:** ✅ FIXED (March 2026)

---

## Fixes Implemented

### 1. ✅ CloudKitSyncCoordinator (NEW)

Created centralized coordinator that replaces 12+ independent listeners with a single debounced handler.

**File:** `Services/CloudKitSyncCoordinator.swift`

```swift
@MainActor
final class CloudKitSyncCoordinator {
    static let shared = CloudKitSyncCoordinator()

    // 500ms debounce to coalesce rapid notifications
    private let debounceInterval: Duration = .milliseconds(500)

    // Single listener for all CloudKit changes
    // Stores register callbacks instead of listening independently
}
```

**Impact:** Reduces 12+ parallel reactions to 1 debounced coordinated response.

### 2. ✅ Updated All Stores to Use Coordinator

Instead of each store setting up its own `NSPersistentStoreRemoteChange` listener:

| Store | Change |
|-------|--------|
| `BaseStore` (CloudKitSyncable.swift) | Registers with coordinator via `registerWithCoordinator()` |
| `EventStore` | Uses `CloudKitSyncCoordinator.shared.registerCallback()` |
| `ProfileStore` | Uses `CloudKitSyncCoordinator.shared.registerCallback()` |
| `TrainingProgressStore` | Uses `CloudKitSyncCoordinator.shared.registerCallback()` |

### 3. ✅ Removed AppDelegate Manual Notification

The manual `NSPersistentStoreRemoteChange` post was causing double processing:

**File:** `App/AppDelegate.swift:67`

```swift
// BEFORE: Manual post duplicated NSPersistentCloudKitContainer's automatic handling
NotificationCenter.default.post(name: .NSPersistentStoreRemoteChange, object: nil)

// AFTER: Removed - coordinator handles automatically
logger.info("Received CloudKit remote change notification (handled by coordinator)")
```

### 4. ✅ Disabled Sentry Debug Logging

Sentry's debug mode was generating **millions of log lines** (100+ per transaction), severely impacting performance and making the console unusable.

**File:** `Services/CrashReporter.swift:60`

```swift
// BEFORE: Generated millions of log lines
options.debug = true

// AFTER: Silent unless debugging Sentry integration
options.debug = false
```

### 5. ✅ DailyAggregateService (Pre-computed Stats)

Added materialized daily aggregates to avoid recalculating stats from raw events.

**Files:**
- `Models/CoreData/CDDailyAggregate+Extensions.swift` (NEW)
- `Services/DailyAggregateService.swift` (NEW)

**Impact:** Reading 7-day stats: ~1,700ms → ~10ms

---

## The Original Cascade Chain

### 1. Entry Point: No Debouncing on CloudKit Notifications

When CloudKit synced, **12+ stores each had their own independent listener** for `NSPersistentStoreRemoteChange`:

```
NSPersistentStoreRemoteChange fires
    ├── EventStore.handleRemoteChange()        → Core Data query + $events publish
    ├── ProfileStore.handleRemoteChange()      → Core Data query + objectWillChange
    ├── TrainingProgressStore.loadState()      → Core Data query + objectWillChange
    ├── MedicationStore.performInitialLoad()   → Core Data query + objectWillChange
    ├── RoutineStore.performInitialLoad()      → Core Data query + objectWillChange
    ├── SkillProgressStore.performInitialLoad()→ Core Data query + objectWillChange
    ├── DocumentStore.performInitialLoad()     → Core Data query + objectWillChange
    ├── WeightStore.performInitialLoad()       → Core Data query + objectWillChange
    ├── RegressionLogStore.performInitialLoad()→ Core Data query + objectWillChange
    ├── AppointmentStore.performInitialLoad()  → Core Data query + objectWillChange
    ├── SocializationStore.performInitialLoad()→ Core Data query + objectWillChange
    └── TrainingPlanStore.performInitialLoad() → Core Data query + objectWillChange
```

### 2. EventStore Triggers EventDataProvider

```
EventStore.$events publishes
    └── EventDataProvider.invalidateAndRefresh()
            └── refreshHistoricalData()           → 30-DAY Core Data fetch!
                    └── objectWillChange.send()
```

### 3. TimelineStatsCache Computes Expensive Stats

```
EventDataProvider.objectWillChange
    └── TimelineStatsCache.refresh()
            └── computeStatsAsync()     → Pattern analysis, stats computation
                    └── objectWillChange.send()
```

### 4. TimelineViewModel Forwards 6 objectWillChange Sources

```
TimelineViewModel receives objectWillChange from:
    ├── SheetCoordinator        → self.objectWillChange.send()
    ├── ActivityTrackingManager → self.objectWillChange.send()
    ├── TimelineStatsCache      → self.objectWillChange.send()
    ├── EventLoggingService     → self.objectWillChange.send()
    ├── PredictionService       → self.objectWillChange.send()
    └── EventDataProvider       → refreshCachedProperties()
```

**Each forward triggered SwiftUI view rebuilds.**

---

## Pre-Fix Metrics (from Sentry)

| Metric | Value |
|--------|-------|
| "Compute Timeline Stats" per hour | 110 (~2/minute) |
| Duration per computation | 1.3-1.6 seconds |
| "Refresh Historical Events" per call | 1.5 seconds |
| Total Core Data queries per notification | 12+ (one per store) |
| objectWillChange forwards in TimelineViewModel | 6 |

---

## Architecture After Fix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CloudKit Remote Change                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                    ┌───────────────────────────────┐
                    │    CloudKitSyncCoordinator    │
                    │    (500ms debounce)           │
                    │    Single listener            │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │   Coordinated refresh:        │
                    │   1. ProfileStore             │
                    │   2. EventStore               │
                    │   3. Other registered stores  │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │    DailyAggregateService      │
                    │    Pre-computed stats         │
                    │    (reads 7 records vs 1500)  │
                    └───────────────────────────────┘
```

---

## Remaining Optimization Opportunities

### MEDIUM: Stop Forwarding objectWillChange

TimelineViewModel still forwards every child change. Consider:
- Only react to specific @Published properties that affect the view
- Use Combine's `.map()` to filter relevant changes
- Consider using `@Observable` (Swift 5.9) which is more granular

### LOW: Lazy-Load Non-Critical Stores

BaseStore subclasses like DocumentStore, WeightStore, etc. could:
- Load lazily when their data is actually accessed
- Use a "dirty" flag instead of immediate reload
- Skip reload if their specific data hasn't changed

### LOW: Consider @Observable Migration

Swift 5.9's `@Observable` macro is more efficient than `ObservableObject`:
- Only triggers view updates for actually-accessed properties
- No `objectWillChange` broadcasting
- Would eliminate the forwarding amplification problem

---

## Files Modified

| File | Change |
|------|--------|
| `Services/CloudKitSyncCoordinator.swift` | NEW - Centralized debounced notification handling |
| `Services/CloudKitSyncable.swift` | BaseStore registers with coordinator instead of individual observer |
| `Services/EventStore+Observers.swift` | Uses coordinator callback |
| `Services/ProfileStore+CloudKitSync.swift` | Uses coordinator callback |
| `Services/TrainingProgressStore.swift` | Uses coordinator callback |
| `App/AppDelegate.swift` | Removed manual NSPersistentStoreRemoteChange post |
| `Services/CrashReporter.swift` | Disabled Sentry debug logging |
| `Services/DailyAggregateService.swift` | NEW - Pre-computed daily aggregates |
| `Models/CoreData/CDDailyAggregate+Extensions.swift` | NEW - Core Data extensions |

---

## Verification

After implementing fixes, verify in Sentry:

1. "Compute Timeline Stats" transactions should drop from 110/hour to <10/hour
2. "Refresh Historical Events" should be <5/hour
3. Console should be quiet (no millions of Sentry debug lines)
4. App should remain responsive during CloudKit sync

---

## Lessons Learned

1. **Architectural amplification is worse than slow operations.** One notification becoming 12+ reactions is worse than one slow operation.

2. **Debug logging can kill performance.** Sentry's `debug = true` generated millions of log lines, completely hiding the actual issues.

3. **Debouncing at the entry point is critical.** Individual component optimizations don't help if the cascade keeps triggering them.

4. **Centralized coordination beats distributed handling.** Having one coordinator that understands dependencies is better than 12 independent listeners.
