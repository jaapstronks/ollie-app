# Apple Watch MVP Implementation Plan

**Goal:** Ship a minimal watch app for hands-free logging during walks
**Target:** v2.0 | watchOS 10+ | iOS 17+

---

## Overview

The MVP delivers four core features:
1. **Quick-Log Grid** — 6 buttons for common events
2. **Potty Timer** — Time since last pee with urgency colors
3. **Current Streak** — Outdoor streak with motivational icon
4. **Sleep Status** — Indicator when puppy is sleeping

---

## Prerequisites (Already Done)

- [x] OllieShared Swift Package with watchOS 10 target
- [x] App Intents for logging (LogPeeOutsideIntent, etc.)
- [x] App Groups configured (`group.jaapstronks.Ollie`)
- [x] IntentDataStore for shared data access
- [x] Calculation modules (GapCalculations, StreakCalculations)

---

## Implementation Steps

### Step 1: Create Watch Target in Xcode

1. File > New > Target > watchOS > App
2. Product Name: `OllieWatch`
3. Bundle Identifier: `nl.jaapstronks.Ollie.watchkitapp`
4. Interface: SwiftUI
5. Life Cycle: SwiftUI App
6. Language: Swift

**Configure target:**
- Add OllieShared as dependency (Project > OllieWatch > Frameworks > Add OllieShared)
- Add App Group capability: `group.jaapstronks.Ollie`
- Set deployment target: watchOS 10.0

**Files created automatically:**
- `OllieWatch/OllieWatchApp.swift`
- `OllieWatch/ContentView.swift`
- `OllieWatch/Assets.xcassets`

---

### Step 2: Create WatchDataProvider

Port the IntentDataStore pattern for watch-side read access.

**File:** `OllieWatch/Services/WatchDataProvider.swift`

```swift
import Foundation
import OllieShared

/// Provides read access to shared data from App Group container
@MainActor
final class WatchDataProvider: ObservableObject {
    static let shared = WatchDataProvider()

    @Published var lastPeeTime: Date?
    @Published var lastPoopTime: Date?
    @Published var currentStreak: Int = 0
    @Published var isSleeping: Bool = false
    @Published var sleepStartTime: Date?

    private let suiteName = "group.jaapstronks.Ollie"
    private let dataDirectoryName = "data"

    func refresh() {
        // Load recent events from App Group
        // Calculate streak, last pee time, sleep status
        // Update published properties
    }

    private func loadTodayEvents() -> [PuppyEvent] {
        // Read from App Group container
        // Same pattern as IntentDataStore.readEvents(for:)
    }
}
```

**Key methods:**
- `refresh()` — Called on app launch and when returning to foreground
- `loadTodayEvents()` — Reads JSONL from App Group
- `timeSinceLastPee()` — Returns formatted string like "1u 23m"
- `urgencyLevel()` — Returns color based on time elapsed

---

### Step 3: Create Quick-Log View

6-button grid for fast event logging.

**File:** `OllieWatch/Views/QuickLogView.swift`

```swift
import SwiftUI
import AppIntents

struct QuickLogView: View {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            QuickLogButton(
                icon: "drop.fill",
                label: "Pee Out",
                color: .green,
                intent: LogPeeOutsideIntent()
            )
            QuickLogButton(
                icon: "drop.fill",
                label: "Pee In",
                color: .orange,
                intent: LogPeeInsideIntent()
            )
            QuickLogButton(
                icon: "circle.fill",
                label: "Poop Out",
                color: .green,
                intent: LogPoopOutsideIntent()
            )
            QuickLogButton(
                icon: "circle.fill",
                label: "Poop In",
                color: .orange,
                intent: LogPoopInsideIntent()
            )
            QuickLogButton(
                icon: "fork.knife",
                label: "Meal",
                color: .blue,
                intent: LogMealIntent()
            )
            QuickLogButton(
                icon: "sun.max.fill",
                label: "Wake Up",
                color: .yellow,
                intent: LogWakeUpIntent()
            )
        }
    }
}

struct QuickLogButton: View {
    let icon: String
    let label: String
    let color: Color
    let intent: any AppIntent

    var body: some View {
        Button(intent: intent) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(color)
    }
}
```

**Note:** Using `Button(intent:)` executes the App Intent directly — no custom logging code needed on the watch.

---

### Step 4: Create Status View (Main Screen)

Shows potty timer, streak, and sleep status.

**File:** `OllieWatch/Views/StatusView.swift`

```swift
import SwiftUI

struct StatusView: View {
    @ObservedObject var dataProvider = WatchDataProvider.shared

    var body: some View {
        VStack(spacing: 12) {
            // Potty Timer
            if let lastPee = dataProvider.lastPeeTime {
                VStack(spacing: 2) {
                    Text(timeSince(lastPee))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundColor(urgencyColor(for: lastPee))
                    Text("since last pee")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Streak
            HStack {
                Image(systemName: streakIcon)
                    .foregroundColor(streakColor)
                Text("\(dataProvider.currentStreak)")
                    .font(.headline)
            }

            // Sleep indicator
            if dataProvider.isSleeping {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                    Text("Sleeping")
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
        }
    }

    private func timeSince(_ date: Date) -> String {
        // Format as "1u 23m" or "45m"
    }

    private func urgencyColor(for date: Date) -> Color {
        // Green < 1h, Yellow 1-2h, Orange 2-3h, Red > 3h
    }

    private var streakIcon: String {
        StreakCalculations.iconName(for: dataProvider.currentStreak)
    }

    private var streakColor: Color {
        // Use StreakCalculations+iOS extension if available, else basic colors
    }
}
```

---

### Step 5: Wire Up ContentView

Main app structure with TabView for navigation.

**File:** `OllieWatch/ContentView.swift`

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var dataProvider = WatchDataProvider.shared

    var body: some View {
        TabView {
            // Tab 1: Status (potty timer + streak)
            StatusView()
                .containerBackground(.black.gradient, for: .tabView)

            // Tab 2: Quick Log buttons
            QuickLogView()
                .containerBackground(.black.gradient, for: .tabView)
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            dataProvider.refresh()
        }
    }
}
```

---

### Step 6: Add App Intents to Watch Target

The existing App Intents need to be available to the watch target.

**Option A (Recommended):** Move intent implementations to OllieShared
- Pro: Single source of truth
- Con: OllieShared needs WidgetKit dependency for widget refresh

**Option B:** Add intent files to both targets
- Pro: No changes to OllieShared
- Con: Duplicate code risk

**Recommendation:** Start with Option B for MVP, refactor later if needed.

**Files to add to OllieWatch target:**
- `Intents/IntentDataStore.swift`
- `Intents/Intents/LogPeeOutsideIntent.swift`
- `Intents/Intents/LogPoopOutsideIntent.swift`
- `Intents/Intents/LogMealIntent.swift`
- `Intents/Intents/LogWakeUpIntent.swift`
- `Intents/Entities/EventTypeEntity.swift`
- `Intents/Entities/LocationEntity.swift`

Or create watch-specific lightweight versions that just write to App Group.

---

### Step 7: Add Haptic Feedback

Confirm actions with haptic feedback.

```swift
import WatchKit

extension WKInterfaceDevice {
    static func playSuccess() {
        WKInterfaceDevice.current().play(.success)
    }

    static func playClick() {
        WKInterfaceDevice.current().play(.click)
    }
}
```

Add to QuickLogButton's action completion.

---

### Step 8: App Icon & Assets

**Required assets:**
- App icon (1024x1024 for App Store, various sizes for watch)
- Use existing Ollie icon, adapted for circular watch format

**File:** `OllieWatch/Assets.xcassets/AppIcon.appiconset`

---

### Step 9: Testing Checklist

**Simulator testing:**
- [ ] App launches without crash
- [ ] Status view shows potty timer
- [ ] Quick-log buttons are tappable
- [ ] TabView swipe navigation works
- [ ] Data refreshes on app foreground

**Device testing (requires paired watch):**
- [ ] App installs via Xcode
- [ ] Quick-log creates events (check iPhone app)
- [ ] Timer updates reflect new events
- [ ] Haptic feedback on button tap
- [ ] App appears in watch app grid

**Edge cases:**
- [ ] No events yet (empty state)
- [ ] No profile configured
- [ ] App Group container not accessible

---

## File Structure

```
OllieWatch/
├── OllieWatchApp.swift
├── ContentView.swift
├── Assets.xcassets/
│   └── AppIcon.appiconset/
├── Views/
│   ├── StatusView.swift
│   └── QuickLogView.swift
├── Services/
│   └── WatchDataProvider.swift
└── Preview Content/
    └── Preview Assets.xcassets/
```

---

## Potential Issues & Solutions

### Issue: App Intents not available on watch
**Solution:** Ensure intent files are added to OllieWatch target membership, or create watch-specific intents that write directly to App Group.

### Issue: App Group data not syncing
**Solution:** App Group sync is not instant. May take a few seconds. Consider showing "Syncing..." indicator or use WatchConnectivity for real-time updates in v2.1.

### Issue: WidgetKit not available for intent refresh
**Solution:** On watch, skip `WidgetCenter.shared.reloadAllTimelines()` call (widgets are iOS-only in MVP).

### Issue: OllieShared has iOS-only code
**Solution:** Use `#if os(iOS)` / `#if os(watchOS)` conditionals for platform-specific code (e.g., UIColor references).

---

## Success Criteria

MVP is complete when:
1. Watch app installs and launches
2. User can log pee/poop (inside/outside), meal, and wake up from watch
3. Potty timer shows time since last pee
4. Streak counter displays correctly
5. Sleep status shows when puppy is sleeping
6. Events logged on watch appear in iPhone app

---

## Next Steps After MVP

- Watch complications (v2.2)
- Today summary view
- Recent events list
- Walk mode with timer
- Haptic reminders for predicted potty times
